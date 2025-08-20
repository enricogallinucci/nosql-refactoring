import time
import json
import sys
from pathlib import Path
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt


G = nx.DiGraph()
query_frequency_in_workload = 0     # Number of queries per second in the workload


def initialize_nodes():
    for current in G.nodes:
        node = G.nodes[current]
        node["cumulative_duration"] = 0
        if node["kind"] == "Query":
            node["benefit"] = query_frequency_in_workload * node["weight"] * (node["time_before"] - node["time_after"])


def annotate_queries_in_migrations():
    ready = [999]
    visited = []
    while ready:
        current = ready.pop()
        if G.nodes[current]["kind"] == "Query":
            G.nodes[current]["impacted_queries"] = [current]
        else:
            impacted = []
            # DO NOT CONSIDER TRANSITIVE IMPACT ON QUERIES
            for node in [s for s in G.successors(current) if G.nodes[s]["kind"] == "Query"]:
                impacted.extend(G.nodes[node]["impacted_queries"])
            G.nodes[current]["impacted_queries"] = set(impacted)
            G.nodes[current]["related_benefit"] = sum([G.nodes[n]["benefit"] for n in set(impacted) if G.nodes[n]["benefit"] > 0])
            for query in impacted:
                G.nodes[query]["cumulative_duration"] += G.nodes[current]["duration"]
            for prec_mig in G.predecessors(current):
                G.nodes[current]["cumulative_duration"] += G.nodes[prec_mig]["duration"]
        visited.append(current)
        for node in G.predecessors(current):
            if all([n in visited for n in G.successors(node)]):
                ready.append(node)


def load_graph(file_path) -> None:
    global G
    global query_frequency_in_workload

    # Open and load the JSON file
    with open(file_path, 'r') as f:
        graph_elements = json.load(f)
        nodes = [tuple(item) for item in graph_elements.get('nodes')]
        edges = [tuple(item) for item in graph_elements.get('edges')]
        query_frequency_in_workload = graph_elements.get('query_frequency_in_workload', 0)

    G.add_nodes_from(nodes)
    G.add_edges_from(edges)

    initialize_nodes()
    annotate_queries_in_migrations()
    # for i in G.nodes:
    #     print(i, G.nodes[i])


def show_graph():
    shells = [
        [node for node, data in G.nodes(data=True) if data["kind"] == "Query"],
        [node for node, data in G.nodes(data=True) if data["kind"] == "Migration"]
    ]
    labels = {node: data["descr"] for node, data in G.nodes(data=True) if node not in [0, 999]}
    nx.draw_shell(G.subgraph([n for n in G.nodes if n not in [0, 999]]), nlist=shells, labels=labels, with_labels=True, font_weight='bold')
    plt.show()


def increase_enabled_of_plan(query: int):
    global enabled_benefit, pending_benefit

    # We do not need to check if the benefit is positive, because the negative ones are in the tail
    enabled_benefit += G.nodes[query]["benefit"]
    pending_benefit -= G.nodes[query]["benefit"]


def increase_benefit_of_plan(migration: int):
    global cum_benefit, enabled_benefit, pending_duration

    cum_benefit += G.nodes[migration]["duration"] * enabled_benefit
    pending_duration -= G.nodes[migration]["duration"]


def add_to_plan(node: int):
    global plan

    plan.append(node)
    if G.nodes[node]["kind"] == "Migration":
        # Increase the benefit of the current migration
        increase_benefit_of_plan(node)
        # Decrease the pending duration of impacted queries
        # for query in G.nodes[node]["impacted_queries"]:
        #     G.nodes[query]["cumulative_duration"] -= G.nodes[node]["duration"]
    elif G.nodes[node]["kind"] == "Query":
        increase_enabled_of_plan(node)


def get_heuristics(node):
    if G.nodes[node].get("calc_benefit") is None:
        if G.nodes[node]["kind"] == "Phantom":
            G.nodes[node]["h"] = 0
            return

        # Get base h = benefit / duration for the single node
        G.nodes[node]["calc_benefit"] = 0
        G.nodes[node]["calc_duration"] = G.nodes[node]["duration"]
        for q in G.nodes[node]["impacted_queries"]:
            G.nodes[node]["calc_benefit"] += G.nodes[q]["benefit"] * G.nodes[node]["duration"] / G.nodes[q]["cumulative_duration"]
        node_h = G.nodes[node]["calc_benefit"]/G.nodes[node]["duration"] if G.nodes[node]["duration"] > 0 else 0

        # Calculate the heuristic for the successive migrations
        successors = [s for s in G.successors(node) if G.nodes[s]["kind"] == "Migration"]
        for succ in successors:
            get_heuristics(succ)
        
        # Sort the successors by their heuristic value
        successors = sorted(successors, key=lambda x: (G.nodes[x]["calc_benefit"]/G.nodes[x]["calc_duration"],G.nodes[x]["calc_benefit"]), reverse=True)

        # Consider chaining them
        G.nodes[node]["chained_migrations"] = [node]
        for succ in successors:
            weighted_benefit = G.nodes[succ]["calc_benefit"] * G.nodes[node]["duration"] / G.nodes[succ]["cumulative_duration"]
            weighted_duration = G.nodes[succ]["duration"] * G.nodes[node]["duration"] / G.nodes[succ]["cumulative_duration"]
            cum_h = (G.nodes[node]["calc_benefit"] + weighted_benefit) / (G.nodes[node]["calc_duration"] + G.nodes[succ]["calc_duration"])
            if cum_h >= node_h:
                G.nodes[node]["calc_benefit"] += weighted_benefit
                G.nodes[node]["calc_duration"] += G.nodes[succ]["calc_duration"]
                if G.nodes[node]["duration"] == G.nodes[succ]["cumulative_duration"]:
                    G.nodes[node]["chained_migrations"].extend(G.nodes[succ]["chained_migrations"])
            else:
                break


    # print("Heuristics:", nodes, "->", heuristics)


def split_ready_nodes(nodes: list[int]) -> list[int]:
    global plan_tail, plan_pretail

    ready_migrations = []
    for node in nodes:
        if G.nodes[node]["kind"] == "Query" and G.nodes[node]["benefit"] > 0:
            add_to_plan(node)               # Beneficial queries are added to the plan as soon as found to be ready
        elif G.nodes[node]["kind"] == "Query" and G.nodes[node]["benefit"] <= 0:
            plan_tail.append(node)          # Queries with negative benefit go at the end of the plan
        # elif G.nodes[node]["kind"] == "Migration" and all(G.nodes[q]["benefit"] <= 0 for q in G.nodes[node]["impacted_queries"]):
        #     plan_pretail.append(node)       # Migrations that do not enable any query with positive benefit are the last ones
            # We need to add now the ready successors to the pretail, as well
            #assert not split_ready_nodes([s for s in G.successors(node) if all([p in plan+plan_pretail for p in G.predecessors(s)])]), f"If a node has not positive impacted queries, its successors {G.successors(node)} should neither have them"
        elif G.nodes[node]["kind"] == "Migration":
            ready_migrations.append(node)   # Other migrations require scheduling
        else:
            raise ValueError("Unexpected node kind")
    return ready_migrations


def greedy_search(ready_node):
    global plan, plan_pretail

    for node in [s for s in G.successors(ready_node)]:
        get_heuristics(node)

    ready_nodes = [s for s in G.successors(ready_node)]
    while ready_nodes:
        # Sort them by heuristic value
        heuristics = [G.nodes[n]["calc_benefit"]/G.nodes[n]["calc_duration"] if G.nodes[n]["calc_duration"]>0 else 0 for n in ready_nodes]
        print("Heuristics:", ready_nodes, "->", heuristics)
        current = ready_nodes[heuristics.index(max(heuristics))]
        add_to_plan(current)
        ready_nodes.remove(current)
        
        next_ready_nodes = [s for s in G.successors(current) if all([p in plan+plan_pretail for p in G.predecessors(s)]) and G.nodes[s]["kind"]!="Phantom"]
        ready_nodes.extend(split_ready_nodes(next_ready_nodes))
        for chained in G.nodes[current]["chained_migrations"]:
            if chained != current:
                add_to_plan(chained)
                if chained not in ready_nodes:
                    print(f"Warning: Chained migration {chained} not in ready nodes, but should be added to the plan")
                ready_nodes.remove(chained)
                chained_next_ready_nodes = [s for s in G.successors(chained) if all([p in plan+plan_pretail for p in G.predecessors(s)])]
                ready_nodes.extend(split_ready_nodes(chained_next_ready_nodes))
    
    for current in plan_pretail:    # Append migrations that do not enable any query
        add_to_plan(current)
    plan.extend(plan_tail)          # Append queries with negative benefit

    # print("Plan after greedy search:", plan)
        

    # start sorting

    # while ready_nodes:
    #     heuristics = get_heuristics(ready_nodes)
    #     current = ready_nodes[heuristics.index(max(heuristics))]
    #     add_to_plan(current)
    #     ready_nodes.remove(current)
    #     # Find new nodes that became ready
    #     next_ready_nodes = [s for s in G.successors(current) if all([p in plan+plan_pretail for p in G.predecessors(s)])]
    #     ready_nodes.extend(split_ready_nodes(next_ready_nodes))
    # for current in plan_pretail:    # Append migrations that do not enable any query
    #     add_to_plan(current)
    # plan.extend(plan_tail)          # Append queries with negative benefit
    # plan.remove(0)                  # Remove the phantom


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    if len(sys.argv) > 2 and sys.argv[2] == "show":
        show_graph()
    else:
        print("================================================================================= Greedy with the right heuristic incrementally computed")
        cum_benefit = 0             # Cumulative benefit of the plan
        enabled_benefit = 0         # Benefit enabled up to now (adding pending benefit should give a constant value)
        pending_benefit = sum([G.nodes[n]["benefit"] for n in G.nodes if G.nodes[n]["kind"] == "Query" and G.nodes[n]["benefit"] > 0])
        pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if G.nodes[n]["kind"] == "Migration"])  # Duration of the migration tasks to be planned
        plan = []
        plan_tail = []              # Queries with negative benefit
        plan_pretail = []           # Migrations not required by any query

        start = time.time()
        greedy_search(0)  # Start the search by the phantom
        end = time.time()
        print(f"Greedy search executed in {(end - start):.2f} seconds")
        print(f"Plan: {plan}")
        print(f"Scheduling benefit: {cum_benefit:.2f}")
