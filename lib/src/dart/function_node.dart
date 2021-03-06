part of tensorflow;

class Func {
  final int _pointer;
  final String name;
  Func gradient;
  int _graphPointer;

  Func._(this._pointer, this.name);

  static int _fromFunctionDef(Uint8List functionDef)
      native "FunctionNode_from_function_def";

  factory Func.fromFunctionDef(FunctionDef functionDef) {
    return new Func._(_fromFunctionDef(functionDef.writeToBuffer()),
        functionDef.signature.name);
  }

  static Tuple3<int, String, int> _fromGraph(
      Graph graph,
      String name,
      List<Output> outputs,
      List<String> outputNames,
      String description,
      List<Output> inputs,
      int nOpers,
      List<int> operations,
      bool appendHashToName) native "FunctionNode_from_graph";

  factory Func(String name, void Function(FuncBuilder) build,
      {Func gradient, Graph existingGraph}) {
    var builder = existingGraph == null
        ? new FuncBuilder._(name)
        : new FuncBuilder._fromExisting(existingGraph, name);
    withScope(builder.graph, () => build(builder));
    var result = _fromGraph(
        builder.graph,
        builder.name,
        builder.outputs.values.toList(),
        builder.outputs.keys.toList(),
        builder.description,
        builder.arguments._args.values.toList(),
        -1,
        [],
        builder.appendHashToName);
    builder.graph.close();

    var code = _codeFrom(result.item1);
    if (code != Code.ok) throw new TensorFlowException(code, result.item2);
    return new Func._(result.item3, name)..gradient = gradient;
  }

  Tuple3<int, String, Uint8List> _toFunctionDef()
      native "FunctionNode_to_function_def";

  FunctionDef toFunctionDef() {
    var result = _toFunctionDef();
    var code = _codeFrom(result.item1);
    if (code != Code.ok) throw new TensorFlowException(code, result.item2);
    return new FunctionDef.fromBuffer(result.item3);
  }

  void copyIntoGraph({Graph graph}) {
    (graph ?? defaultGraph).copyFunction(this, grad: gradient);
  }

  Operation<T> call<T>(List<Output> arguments,
      {Graph graph, String operationName}) {
    graph ??= defaultGraph;
    copyIntoGraph(graph: graph);
    var desc = graph.newOperation(
        name, operationName ??= graph._scope.uniqueName('$name/'));
    arguments.forEach(desc.addInput);
    return desc.finish();
  }
}

class FuncArguments {
  final Map<String, Output> _args = {};
  int _argCount = 0;

  FuncArguments._();

  Output<T> get<T>(String name, {@required DataType dtype, Shape shape}) {
    return _args.putIfAbsent(name, () {
      _argCount++;
      shape ??= Shape.scalar;
      return placeholder(dtype: dtype, shape: shape, operationName: name);
    });
  }
}

class FuncBuilder {
  final String name;
  final FuncArguments arguments = new FuncArguments._();
  final Graph graph;
  final Map<String, Output> outputs = {};
  bool appendHashToName = false;
  String description;

  FuncBuilder._(this.name) : graph = new Graph();

  FuncBuilder._fromExisting(this.graph, this.name);
}
