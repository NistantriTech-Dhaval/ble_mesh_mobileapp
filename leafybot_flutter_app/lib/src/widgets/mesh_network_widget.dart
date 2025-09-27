import 'package:flutter/material.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

class MeshNetworkDataWidget extends StatefulWidget {
  final IMeshNetwork meshNetwork;

  const MeshNetworkDataWidget({Key? key, required this.meshNetwork})
      : super(key: key);

  @override
  State<MeshNetworkDataWidget> createState() => _MeshNetworkDataWidgetState();
}

class _MeshNetworkDataWidgetState extends State<MeshNetworkDataWidget> {
  List<ProvisionedMeshNode> _nodes = [];
  List<GroupData> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadNetworkData();
  }

  @override
  void didUpdateWidget(covariant MeshNetworkDataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadNetworkData();
  }

  Future<void> _loadNetworkData() async {
    final nodes = await widget.meshNetwork.nodes;
    final groups = await widget.meshNetwork.groups;
    setState(() {
      _nodes = nodes;
      _groups = groups;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mesh Network ID IOS: ${widget.meshNetwork.id}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_nodes.isNotEmpty) ...[
            Text('IOS Devices (${_nodes.length}):',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return NodeWidget(
                  node: node,
                  meshNetwork: widget.meshNetwork,
                  identifier: 'node-$index');
            }),
            const SizedBox(height: 16),
          ],
          if (_groups.isNotEmpty) ...[
            Text('Groups (${_groups.length}):',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._groups.map((group) =>
                GroupWidget(group: group, meshNetwork: widget.meshNetwork)),
          ],
        ],
      ),
    );
  }
}

class NodeWidget extends StatefulWidget {
  final ProvisionedMeshNode node;
  final IMeshNetwork meshNetwork;
  final String identifier;

  const NodeWidget({
    Key? key,
    required this.node,
    required this.meshNetwork,
    required this.identifier,
  }) : super(key: key);

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  var name = "";
  int unicastaddress=0;
  @override
  void initState() {
    load_name();
  }

  load_name() async {
    name = await widget.node.name;
    unicastaddress = await widget.node.unicastAddress;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('UUID: ${widget.node.uuid}'),
            Text(
                'Unicast Address: ${unicastaddress}'),
            FutureBuilder<List<ElementData>>(
              future: widget.node.elements,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Elements: Loading...');
                } else if (snapshot.hasError) {
                  return const Text('Elements: Error loading');
                } else if (snapshot.hasData) {
                  final elements = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elements: ${elements.length}'),
                      const SizedBox(height: 4),
                      ...elements.asMap().entries.map((entry) {
                        final index = entry.key;
                        final element = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• Element $index: ${element.name}'),
                              const SizedBox(height: 4),
                              if (element.models.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: element.models.map((model) {
                                      final modelId = model.modelId.toRadixString(16).toUpperCase();
                                      final modelName = model.modelId ?? 'Unknown Model';
                                      return Text('- Model: $modelName (0x$modelId)');
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                } else {
                  return const Text('Elements: 0');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GroupWidget extends StatelessWidget {
  final GroupData group;
  final IMeshNetwork meshNetwork;

  const GroupWidget({Key? key, required this.group, required this.meshNetwork})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(group.name ?? 'Unnamed Group'),
        subtitle:
            Text('Address: 0x${group.address.toRadixString(16).toUpperCase()}'),
        trailing: const Icon(Icons.group),
      ),
    );
  }
}
