import time
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

nodes = [
    (0,  {"kind": "Phantom",    "descr": "Start",                             "duration": 0}),
    (1,  {"kind": "Migration",  "descr": "PhotoObjAll_Galaxy",                "duration": 119.47}),
    # (2,  {"kind": "Migration",  "descr": "PhotoObjAll_GalaxyComplementary",   "duration": 94.22}),
    (3,  {"kind": "Migration",  "descr": "PhotoObjAll_Primary",               "duration": 18.11}),
    # (4,  {"kind": "Migration",  "descr": "PhotoObjAll_PrimaryComplementary",  "duration": 177.99}),
    (5,  {"kind": "Migration",  "descr": "PhotoObjAll_Other",                 "duration": 237.49}),
    (6,  {"kind": "Migration",  "descr": "SpecObjAll",                        "duration": 34.74}),
    (7,  {"kind": "Migration",  "descr": "Photoz",                            "duration": 0.3}),
    # (8,  {"kind": "Migration",  "descr": "Photoz_Complementary",              "duration": 15.82}),
    # (9,  {"kind": "Migration",  "descr": "PhotozRF",                          "duration": 1.3}),
    # (10, {"kind": "Migration",  "descr": "PhotozRF_Complementary",            "duration": 5.36}),
    (21, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.1066, "time_before": 0.000000533299, "time_after": 0.00000079132}),
    (22, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0133, "time_before": 7.473494, "time_after": 17.310399}),
    (23, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.1413, "time_before": 448.062937, "time_after": 8.512533}),
    (24, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0547, "time_before": 1.176855, "time_after": 1.145305}),
    (25, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0468, "time_before": 0.000000026124, "time_after": 2.026613}),
    (26, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.1078, "time_before": 2.087132, "time_after": 3.454291}),
    # (27, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0349, "time_before": 0, "time_after": 0}),
    # (28, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0263, "time_before": 0, "time_after": 0}),
    # (29, {"kind": "Query",      "descr": "Q1",                                "duration": 0, "weight": 0.0273, "time_before": 0, "time_after": 0}),
    (99, {"kind": "Phantom",    "descr": "End",                               "duration": 0})
]

edges = [
    (0, 1), (0, 3), (0, 5), (0, 6), (0, 7),
    #(0, 2), (0, 4), (0, 8), (0, 9), (0, 10),
    (1, 21), (3, 21),
    (1, 22), (3, 22),
    (1, 23),
    (6, 24),
    (1, 25), (7, 25),
    (1, 26), (3, 26), (5, 26),
    (21, 99), (22, 99), (23, 99), (24, 99), (25, 99), (26, 99), #(27, 99), (28, 99), (29, 99),
    #(2, 99), (4, 99), (8, 99), (9, 99), (10, 99)
]


def show_graph(G):
    nx.draw_shell(G, with_labels=True, font_weight='bold')
    plt.show()


def add_benefit_to_nodes(nodes):
    for node in nodes:
        if node[1]["kind"] == "Query":
            node[1]["benefit"] = node[1]["weight"] * (node[1]["time_before"] - node[1]["time_after"])


def get_ready_nodes(nodes, visited) -> list[int]:
    ready = []
    for node in nodes:
        if node[0] not in visited and all([n in visited for n in G.predecessors(node[0])]):
            ready.append(node[0])
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
    add_benefit_to_nodes(nodes)

    G = nx.DiGraph()
    G.add_nodes_from(nodes)
    G.add_edges_from(edges)

    plan = [0]
    ready = get_ready_nodes(nodes, plan)
    solution = []
    benefit = 0
    enabled = 0
    best = 0
    worse = 0
    best_plan = [0]
    worse_plan = [0]

    start = time.time()
    exhaustive_search(plan, ready)
    end = time.time()

    print(f"Elapsed time: {(end - start):.2f} seconds")

    print(f"Best plan: {best_plan} -> {best:.2f}")
    print(f"Worse plan: {worse_plan} -> {worse:.2f}")

