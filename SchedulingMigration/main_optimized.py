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
        node["planned"] = False
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
            for node in G.successors(current):
                impacted.extend(G.nodes[node]["impacted_queries"])
            G.nodes[current]["impacted_queries"] = set(impacted)
            G.nodes[current]["related_benefit"] = sum([G.nodes[n]["benefit"] for n in set(impacted) if G.nodes[n]["benefit"] > 0])
            for query in impacted:
                G.nodes[query]["cumulative_duration"] += G.nodes[current]["duration"]
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


def mark_as_planned(node):
    global plan
    plan.append(node)
    for query in G.nodes[node]["impacted_queries"]:
        G.nodes[query]["cumulative_duration"] -= G.nodes[node]["duration"]
    G.nodes[node]["planned"] = True


def increase_enabled_of_plan(node: int):
    global enabled, pending_benefit
    # We do not need to check if the benefit is positive, because the negative ones are in the tail
    enabled += G.nodes[node]["benefit"]
    pending_benefit -= G.nodes[node]["benefit"]


def increase_benefit_of_plan(node: int):
    global benefit, enabled, pending_duration
    benefit += G.nodes[node]["duration"] * enabled
    pending_duration -= G.nodes[node]["duration"]


def get_heuristics(nodes) -> list[int]:
    global pending_benefit, pending_duration
    # add_cumulative_duration_to_nodes()
    heuristics = []
    for node in nodes:
        h = 0
        if G.nodes[node]["kind"] != "Phantom":
            for q in G.nodes[node]["impacted_queries"]:
                if G.nodes[q]["benefit"] > 0:
                    # The heuristic takes:
                    # 1) The maximum duration left after executing all the requirements of a query
                    # 2) The benefit of the query
                    # 3) The percentage of the requirements that this migration represents
                    h += (pending_duration - G.nodes[q]["cumulative_duration"]) * G.nodes[q]["benefit"] * (G.nodes[node]["duration"] / G.nodes[q]["cumulative_duration"])
            # The heuristic subtracts the benefit removed from all the other queries that do not benefit if we do the migration before and not after them
            h -= (pending_benefit - G.nodes[node]["related_benefit"]) * G.nodes[node]["duration"]
        heuristics.append(h)
    #print("All together:", nodes, "->", heuristics)
    return heuristics


def split_ready_nodes(nodes: list[int]) -> list[int]:
    global plan_tail, plan_pretail

    ready_migrations = []
    for node in nodes:
        if G.nodes[node]["kind"] == "Query" and G.nodes[node]["benefit"] > 0:
            mark_as_planned(node)
            increase_enabled_of_plan(node)  # This has a constant cost, because every query node becomes ready only once
        elif G.nodes[node]["kind"] == "Query" and G.nodes[node]["benefit"] <= 0:
            plan_tail.append(node)
        elif G.nodes[node]["kind"] == "Migration" and list(G.successors(node)) == [999]:
            plan_pretail.append(node)
        elif G.nodes[node]["kind"] == "Migration":
            ready_migrations.append(node)
        else:
            raise ValueError("Unexpected node kind")
    return ready_migrations


def greedy_search(ready):
    global plan

    steps = -1  # No need to count the phantom
    while ready:
        heuristics = get_heuristics(ready)
        current = ready[heuristics.index(max(heuristics))]
        mark_as_planned(current)
        # Increase the benefit of the current migration
        increase_benefit_of_plan(current)
        # Add new nodes that became ready
        next_ready = []
        for j in G.successors(current):
            if j not in plan and all([n in plan for n in G.predecessors(j)]):
                next_ready.append(j)
        ready.remove(current)
        ready.extend(split_ready_nodes(next_ready))
        steps += 1
    for current in plan_pretail:
        mark_as_planned(current)
        # Increase the benefit of the current migration
        increase_benefit_of_plan(current)
        steps += 1
    return steps


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    if len(sys.argv) > 2 and sys.argv[2] == "show":
        show_graph()
    else:
        print("================================================================================= Greedy with the right heuristic incrementally computed")
        benefit = 0
        enabled = 0
        pending_benefit = sum([G.nodes[n]["benefit"] for n in G.nodes if G.nodes[n]["kind"] == "Query" and G.nodes[n]["benefit"] > 0])
        pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if G.nodes[n]["kind"] == "Migration"])
        plan = []
        plan_tail = []      # Queries with negative benefit
        plan_pretail = []   # Migrations not required by any query

        start = time.time()
        steps = greedy_search(ready=[0])
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")

        plan.extend(plan_tail)
        print(f"Greedy plan: {plan}")
        print(f"Scheduling benefit: {benefit:.2f}")

