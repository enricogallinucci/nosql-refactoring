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


def show_graph():
    shells = [
        [node for node, data in G.nodes(data=True) if data["kind"] == "Query"],
        [node for node, data in G.nodes(data=True) if data["kind"] == "Migration"]
    ]
    labels = {node: data["descr"] for node, data in G.nodes(data=True) if node not in [0, 999]}
    nx.draw_shell(G.subgraph([n for n in G.nodes if n not in [0, 999]]), nlist=shells, labels=labels, with_labels=True, font_weight='bold')
    plt.show()


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

    forward_compute_benefits_and_cumulative_durations()
    backward_compute_heuristics()
    print("--------- Heuristics ---------")
    for i in G.nodes:
        print(i, G.nodes[i]["heuristic"])


def forward_compute_benefits_and_cumulative_durations():
    ready = [0]
    visited = []
    # Follow forward topological order to fill cumulative durations
    #   Actually, it is not necessary to follow a topological order if we only use direct duration instead of cumulative duration in the calculation of next node
    while ready:
        current_id = ready.pop()
        current = G.nodes[current_id]
        # current["cumulative_duration"] = current.get("duration", 0) + sum([G.nodes[pred_id]["cumulative_duration"] for pred_id in G.predecessors(current_id)])
        current["cumulative_duration"] = current.get("duration", 0) + sum([G.nodes[pred_id]["duration"] for pred_id in G.predecessors(current_id)])
        if G.nodes[current_id]["kind"] == "Query":
            current["benefit"] = query_frequency_in_workload * current["weight"] * (current["time_before"] - current["time_after"])
        visited.append(current_id)
        for node_id in G.successors(current_id):
            if all([pred_id in visited for pred_id in G.predecessors(node_id)]):
                ready.append(node_id)


def backward_compute_heuristics():
    ready = [999]
    visited = []
    # Follow backward topological order to compute the heuristic
    while ready:
        current_id = ready.pop()
        current = G.nodes[current_id]
        if current["kind"] == "Query":
            if current["benefit"] > 0:
                current["heuristic"] = float('inf')    # We plan positive queries as soon as possible, so we assign them the maximum heuristic
            else:
                current["heuristic"] = float('-inf')   # We plan negative queries as late as possible, so we assign them the minimum heuristic
        elif current["kind"] == "Migration":
            immediate_benefit = 0
            promised_benefit = 0
            promised_duration = 0
            for successor_id in G.successors(current_id):
                successor = G.nodes[successor_id]
                if successor["kind"] == "Query":
                    if successor["benefit"] > 0:
                        immediate_benefit += successor["benefit"] * current["duration"] / successor["cumulative_duration"]
            # Notice that we are multiplying and dividing immediate_benefit by current["duration"] in present_heuristic, but cannot be simplified in the future_heuristic
            present_heuristic = immediate_benefit/current["duration"]
            for successor_id in G.successors(current_id):
                successor = G.nodes[successor_id]
                if successor["kind"] == "Migration" and present_heuristic < successor["heuristic"]:
                    promised_benefit += successor["promised_benefit"]
                    promised_duration += successor["promised_duration"]
            promised_heuristic = (immediate_benefit+promised_benefit)/(current["duration"]+promised_duration)
            if present_heuristic >= promised_heuristic:
                current["heuristic"] = present_heuristic
                current["promised_benefit"] = immediate_benefit
                current["promised_duration"] = current["duration"]
            else:
                current["heuristic"] = promised_heuristic
                current["promised_benefit"] = immediate_benefit+promised_benefit
                current["promised_duration"] = current["duration"]+promised_duration
        else:   # This should be a phantom
            current["heuristic"] = 0
            current["promised_benefit"] = 0
            current["promised_duration"] = 0
        visited.append(current_id)
        for node_id in G.predecessors(current_id):
            if all([succ_id in visited for succ_id in G.successors(node_id)]):
                ready.append(node_id)


def greedy_search(ready_nodes):
    global plan

    while ready_nodes:
        # Find the node of maximum heuristic
        heuristics = [G.nodes[node_id]["heuristic"] for node_id in ready_nodes]
        current_id = ready_nodes[heuristics.index(max(heuristics))]
        plan.append(current_id)
        ready_nodes.remove(current_id)
        # Find new nodes that became ready
        next_ready_nodes = [succ_id for succ_id in G.successors(current_id) if all([pred_id in plan for pred_id in G.predecessors(succ_id)])]
        ready_nodes.extend(next_ready_nodes)
    plan.remove(0)                  # Remove the phantom


def get_benefit_of_plan() -> float:
    global plan

    benefit = 0
    enabled = 0
    for i in range(len(plan)):
        if G.nodes[plan[i]]["kind"] == "Query":
            enabled += G.nodes[plan[i]]["benefit"]
        elif G.nodes[plan[i]]["kind"] == "Migration":
            benefit += G.nodes[plan[i]]["duration"]*enabled
    return benefit


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    if len(sys.argv) > 2 and sys.argv[2] == "show":
        show_graph()
    else:
        print("================================================================================= Greedy with the pre-computed heuristic immutable")
        plan = []

        start = time.time()
        greedy_search([0])  # Start the search by the phantom
        end = time.time()
        print(f"Greedy search executed in {(end - start):.2f} seconds")
        print(f"Plan: {plan}")
        print(f"Scheduling benefit: {get_benefit_of_plan():.2f}")
