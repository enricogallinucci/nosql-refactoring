import time
import json
import sys
from pathlib import Path
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt


G = nx.DiGraph()
benefit = 0
enabled = 0
best = 0
worse = 0
best_plan = [0]
worse_plan = [0]


def load_graph(file_path) -> None:
    global G

    # Open and load the JSON file
    with open(file_path, 'r') as f:
        graph_elements = json.load(f)
        nodes = [tuple(item) for item in graph_elements.get('nodes')]
        edges = [tuple(item) for item in graph_elements.get('edges')]

    add_benefit_to_nodes(nodes)

    G.add_nodes_from(nodes)
    G.add_edges_from(edges)


def show_graph():
    nx.draw_shell(G, with_labels=True, font_weight='bold')
    plt.show()


def add_benefit_to_nodes(nodes):
    for node in nodes:
        if node[1]["kind"] == "Query":
            node[1]["benefit"] = node[1]["weight"] * (node[1]["time_before"] - node[1]["time_after"])


def get_ready_nodes(nodes, visited) -> list[int]:
    ready = []
    for i in nodes:
        if i not in visited and all([n in visited for n in G.predecessors(i)]):
            ready.append(i)
    return ready


def get_benefit_of_plan(plan) -> float:
    benefit = 0
    enabled = 0
    for i in range(len(plan)):
        if G.nodes[plan[i]]["kind"] == "Query":
            enabled += G.nodes[plan[i]]["benefit"]
        elif G.nodes[plan[i]]["kind"] == "Migration":
            benefit += G.nodes[plan[i]]["duration"]*enabled
    return benefit


def exhaustive_search(plan, ready):
    global benefit
    global enabled
    global best, best_plan
    global worse, worse_plan

    if 99 in ready:
        if benefit > best:
            best, best_plan = benefit, plan.copy()
        if benefit < worse:
            worse, worse_plan = benefit, plan.copy()
        #print("Plan found:", plan, benefit)
    else:
        for i in range(len(ready)):
            current = ready[i]
            plan.append(current)
            # Increase the benefit up to now
            if G.nodes[current]["kind"] == "Query":
                enabled += G.nodes[current]["benefit"]
            elif G.nodes[current]["kind"] == "Migration":
                benefit += G.nodes[current]["duration"] * enabled
            # Add new nodes that became ready
            next_ready = [n for n in ready if n != current]
            for j in G.successors(current):
                if j not in plan and all([n in plan for n in G.predecessors(j)]):
                    next_ready.append(j)
            # Recursive call
            exhaustive_search(plan, next_ready)
            # Remove the benefit
            if G.nodes[current]["kind"] == "Query":
                enabled -= G.nodes[current]["benefit"]
            elif G.nodes[current]["kind"] == "Migration":
                benefit -= G.nodes[current]["duration"] * enabled
            # Remove the node from the plan
            plan.pop()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("inputs").joinpath(sys.argv[1]))

    plan = [0]

    start = time.time()
    exhaustive_search(plan, get_ready_nodes(G.nodes, plan))
    end = time.time()

    print(f"Elapsed time: {(end - start):.2f} seconds")

    print(f"Best plan: {best_plan} -> {best:.2f}")
    print(f"Worse plan: {worse_plan} -> {worse:.2f}")

