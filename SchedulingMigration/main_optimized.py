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
    while ready != []:
        current = ready.pop()
        if G.nodes[current]["kind"] == "Query":
            G.nodes[current]["impacted_queries"] = [current]
        else:
            impacted = []
            for node in G.successors(current):
                impacted.extend(G.nodes[node]["impacted_queries"])
            G.nodes[current]["impacted_queries"] = impacted
            G.nodes[current]["related_benefit"] = sum([G.nodes[n]["benefit"] for n in impacted if G.nodes[n]["benefit"] > 0])
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
    #     print(G.nodes[i])


def show_graph():
    shells = [
        [node for node, data in G.nodes(data=True) if data["kind"] == "Query"],
        [node for node, data in G.nodes(data=True) if data["kind"] == "Migration"]
    ]
    labels = {node: data["descr"] for node, data in G.nodes(data=True) if node not in [0, 999]}
    nx.draw_shell(G.subgraph([n for n in G.nodes if n not in [0, 999]]), nlist=shells, labels=labels, with_labels=True, font_weight='bold')
    plt.show()


def mark_as_planned(nodes):
    global plan
    plan.extend(nodes)
    for node in nodes:
        for query in G.nodes[node]["impacted_queries"]:
            G.nodes[query]["cumulative_duration"] -= G.nodes[node]["duration"]
        G.nodes[node]["planned"] = True


def increase_enabled_of_plan(nodes: list[int]):
    global enabled, pending_benefit
    for i in nodes:
        # We do not need to check if the benefit is positive, because the negative ones are in the tail
        enabled += G.nodes[i]["benefit"]
        pending_benefit -= G.nodes[i]["benefit"]


def increase_benefit_of_plan(node: int):
    global benefit, enabled, pending_duration
    benefit += G.nodes[node]["duration"] * enabled
    pending_duration -= G.nodes[node]["duration"]


def get_heuristics_alltogether_incremental(nodes) -> list[int]:
    global pending_benefit, pending_duration
    # add_cumulative_duration_to_nodes()
    heuristics = []
    for node in nodes:
        h = 0
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


def greedy_search(ready, plan_tail, plan_pretail, heuristic_function):
    global steps
    global benefit

    steps += 1

    # Add all queries to the plan at once (no need for backtracking)
    ready_queries = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] > 0]
    tail = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] <= 0]
    pretail = [i for i in ready if G.nodes[i]["kind"] == "Migration" and G.successors(i) == [999]]
    plan_tail.extend(tail)
    plan_pretail.extend(pretail)
    mark_as_planned(ready_queries)
    increase_enabled_of_plan(ready_queries)  # This has a constant cost, because every query node becomes ready only once
    # Take one more migration
    ready_migrations = [i for i in ready if G.nodes[i]["kind"] == "Migration"]
    if not ready_migrations:
        plan.extend(plan_pretail+plan_tail)
        print(f"Greedy plan: {plan} -> {benefit:.2f}")
    else:
        heuristics = heuristic_function(ready_migrations)
        current = ready_migrations[heuristics.index(max(heuristics))]
        mark_as_planned([current])
        # Increase the benefit of the current migration
        increase_benefit_of_plan(current)  # This has a constant cost, because every migration node becomes ready only once
        # Add new nodes that became ready
        next_ready = [n for n in ready_migrations if n != current]
        for j in G.successors(current):
            if j not in plan and all([n in plan for n in G.predecessors(j) if n != 0]):
                next_ready.append(j)
        # Recursive call
        greedy_search(next_ready, plan_tail, plan_pretail, heuristic_function)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    if len(sys.argv) > 2 and sys.argv[2] == "show":
        show_graph()
    else:
        print("================================================================================= Greedy with the combination of both++ incrementally computed")
        steps = 0
        benefit = 0
        enabled = 0
        pending_benefit = sum([G.nodes[n]["benefit"] for n in G.nodes if G.nodes[n]["kind"] == "Query" and G.nodes[n]["benefit"] > 0])
        pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if G.nodes[n]["kind"] == "Migration"])
        plan = []

        start = time.time()
        greedy_search(ready=[n for n in G.nodes if list(G.predecessors(n)) == [0]], plan_tail=[], plan_pretail=[], heuristic_function=get_heuristics_alltogether_incremental)
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")
