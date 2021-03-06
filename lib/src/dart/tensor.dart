part of tensorflow;

/// A statically typed multi-dimensional array whose elements are of a type described by T.
///
/// Resources consumed by the Tensor object must be explicitly freed by invoking the [close]() method when the object is no longer needed.
class Tensor {
  final int _dataType;
  final Uint8List _data;
  final Int64List _shape;

  Tensor._(this._dataType, this._data, this._shape);

  factory Tensor(DataType dtype, Shape shape, Uint8List data) =>
      new Tensor._(dtype.value, data, shape.dimensions);

  /// Converts an arbitrary value into a Tensor.
  ///
  /// [dtype] may be ignored.
  factory Tensor.from(value, {DataType dtype}) {
    if (value is Tensor) return value.cast(dtype ?? value.dtype);
    if (value is String) return new Tensor.fromString(value);
    if (value is bool) return new Tensor.fromBool(value);
    if (value is double) return new Tensor.fromDouble(value, dtype: dtype);
    if (value is int) return new Tensor.fromInt(value, dtype: dtype);
    if (value is Shape) return new Tensor.fromShape(value);
    if (value is Int32)
      return new Tensor.fromInt(value.toInt(), dtype: DataType.DT_INT32);
    if (value is Int64)
      return new Tensor.fromInt(value.toInt(), dtype: DataType.DT_INT64);
    if (value is Int8List) return new Tensor.fromInt8List(value);
    if (value is Int16List) return new Tensor.fromInt16List(value);
    if (value is Int32List) return new Tensor.fromInt32List(value);
    if (value is Int64List) return new Tensor.fromInt64List(value);
    if (value is Uint8List) return new Tensor.fromUint8List(value);
    if (value is Uint16List) return new Tensor.fromUint16List(value);
    if (value is Uint32List) return new Tensor.fromUint32List(value);
    if (value is Uint64List) return new Tensor.fromUint64List(value);
    if (value is Float32List) return new Tensor.fromFloat32List(value);
    if (value is Float64List) return new Tensor.fromFloat64List(value);

    if (value is List) {
      if (value.isEmpty) return new Tensor.fromInt64List(new Int64List(0));
      var first = value.first;

      if (first is int)
        return new Tensor.fromInt32List(new Int32List.fromList(value));
      if (first is double)
        return new Tensor.fromFloat32List(new Float32List.fromList(value));
      if (first is Iterable) {
        var shape = Shape.infer(value);
        return new Tensor.from(flatten(value), dtype: dtype).reshape(shape);
      }
      // TODO: String list?
    }

    throw new ArgumentError('Cannot convert $value into a Tensor.');
  }

  factory Tensor.fromBuffer(DataType dtype, Shape shape, ByteBuffer data) =>
      new Tensor(dtype, shape, new Uint8List.view(data));

  //static Tuple3<int, String, Uint8List> _string(String s)
  //    native "Tensors_string";

  factory Tensor.fromString(String s, {bool padding: false}) {
    /*
    var result = _string(s);
    var code = _codeFrom(result.item1);
    if (code != Code.ok) throw new TensorFlowException(code, result.item2);
    return new Tensor._(DataType.DT_STRING.value,
        new Uint8List.view(result.item3.buffer, 9), Shape.scalar.dimensions);
    */
    var bytes = new List.filled(padding ? 8 : 0, 0, growable: true)
      ..addAll(utf8.encode(s));
    //..add(0)

    return new Tensor(
        DataType.DT_STRING, Shape.scalar, new Uint8List.fromList(bytes));
  }

  factory Tensor.fromInt(int n, {DataType dtype: DataType.DT_INT32}) {
    switch (dtype) {
      case DataType.DT_INT8:
        return new Tensor.fromInt8List(new Int8List.fromList([n])).asScalar;
      case DataType.DT_INT16:
        return new Tensor.fromInt16List(new Int16List.fromList([n])).asScalar;
      case DataType.DT_INT32:
        return new Tensor.fromInt32List(new Int32List.fromList([n])).asScalar;
      case DataType.DT_INT64:
        return new Tensor.fromInt64List(new Int64List.fromList([n])).asScalar;
      case DataType.DT_UINT8:
        return new Tensor.fromUint8List(new Uint8List.fromList([n])).asScalar;
      case DataType.DT_UINT16:
        return new Tensor.fromUint16List(new Uint16List.fromList([n])).asScalar;
      case DataType.DT_UINT32:
        return new Tensor.fromUint32List(new Uint32List.fromList([n])).asScalar;
      case DataType.DT_UINT64:
        return new Tensor.fromUint64List(new Uint64List.fromList([n])).asScalar;
    }

    if (dtype == null) return new Tensor.fromInt(n);
    throw new ArgumentError('Not an integer type: $dtype');
  }

  factory Tensor.fromDouble(double n, {DataType dtype: DataType.DT_FLOAT}) {
    switch (dtype) {
      case DataType.DT_FLOAT:
        return new Tensor.fromFloat32List(new Float32List.fromList([n]))
            .asScalar;
      case DataType.DT_DOUBLE:
        return new Tensor.fromFloat64List(new Float64List.fromList([n]))
            .asScalar;
    }

    if (dtype == null) return new Tensor.fromDouble(n);
    throw new ArgumentError('Not a float/double type: $dtype');
  }

  factory Tensor.fromShape(Shape shape) {
    if (shape.size == 0)
      throw 'Cannot convert a scalar (empty) Shape to a Tensor.';
    return new Tensor.fromInt64List(shape.dimensions).reshape(shape);
  }

  factory Tensor.fromBool(bool b) =>
      new Tensor.fromUint8List(new Uint8List.fromList([b ? 1 : 0])).asScalar;

  factory Tensor.fromInt8List(Int8List list) => new Tensor.fromBuffer(
      DataType.DT_INT8, new Shape(list.length), list.buffer);

  factory Tensor.fromInt16List(Int16List list) => new Tensor.fromBuffer(
      DataType.DT_INT16, new Shape(list.length), list.buffer);

  factory Tensor.fromInt32List(Int32List list) => new Tensor.fromBuffer(
      DataType.DT_INT32, new Shape(list.length), list.buffer);

  factory Tensor.fromInt64List(Int64List list) => new Tensor.fromBuffer(
      DataType.DT_INT64, new Shape(list.length), list.buffer);

  factory Tensor.fromUint8List(Uint8List list) =>
      new Tensor(DataType.DT_UINT8, new Shape(list.length), list);

  factory Tensor.fromUint16List(Uint16List list) => new Tensor.fromBuffer(
      DataType.DT_UINT16, new Shape(list.length), list.buffer);

  factory Tensor.fromUint32List(Uint32List list) => new Tensor.fromBuffer(
      DataType.DT_UINT32, new Shape(list.length), list.buffer);

  factory Tensor.fromUint64List(Uint64List list) => new Tensor.fromBuffer(
      DataType.DT_UINT64, new Shape(list.length), list.buffer);

  factory Tensor.fromFloat32List(Float32List list) => new Tensor.fromBuffer(
      DataType.DT_FLOAT, new Shape(list.length), list.buffer);

  factory Tensor.fromFloat64List(Float64List list) => new Tensor.fromBuffer(
      DataType.DT_DOUBLE, new Shape(list.length), list.buffer);

  /// Returns this [Tensor] as a 0-dimensional scalar.
  Tensor get asScalar => reshape(Shape.scalar);

  /// Casts this tensor to another type.
  ///
  /// WARNING: This does not resize data, which may lead to segfaults
  /// if the output type is larger than the source type.
  Tensor cast(DataType type) => new Tensor(type, shape, _data);

  /// Returns this [Tensor] as a n-dimensional scalar.
  Tensor reshape(Shape newShape) =>
      new Tensor(DataType.valueOf(_dataType), newShape, _data);

  /// The [DataType] of elements stored in the Tensor.
  DataType get dtype => DataType.valueOf(_dataType);

  /// A object that can read the contents of this tensor.
  ByteData get byteData => new ByteData.view(_data.buffer);

  /// Returns the value in a scalar [bool] tensor.
  bool get asBool => asUint8 == 1;

  /// Returns the value in a scalar `FLOAT` tensor.
  double get asFloat32 => byteData.getFloat32(0);

  /// Returns the value in a scalar `DUBLE` tensor.
  double get asFloat64 => byteData.getFloat64(0);

  /// Returns the value in a scalar `INT8` tensor.
  int get asInt8 => byteData.getInt8(0);

  /// Returns the value in a scalar `INT16` tensor.
  int get asInt16 => byteData.getInt16(0);

  /// Returns the value in a scalar `INT32` tensor.
  int get asInt32 => byteData.getInt32(0);

  /// Returns the value in a scalar `INT64` tensor.
  int get asInt64 => byteData.getInt64(0);

  /// Returns the value in a scalar `UINT8` tensor.
  int get asUint8 => byteData.getUint8(0);

  /// Returns the value in a scalar `UINT16` tensor.
  int get asUint16 => byteData.getUint16(0);

  /// Returns the value in a scalar `UINT32` tensor.
  int get asUint32 => byteData.getUint32(0);

  /// Returns the value in a scalar `UINT64` tensor.
  int get asUint64 => byteData.getUint64(0);

  /// Returns the value in a scalar [String] tensor.
  String get asString => dtype == DataType.DT_STRING
      ? new String.fromCharCodes(new Uint8List.view(asUint8List.buffer))
      : throw new ArgumentError('Not a string type: $dtype');

  /// Returns the value in a scalar UTF-8 [String] tensor.
  String get asUtf8String => dtype == DataType.DT_STRING
      ? utf8.decode(new Uint8List.view(asUint8List.buffer),
          allowMalformed: true)
      : throw new ArgumentError('Not a string type: $dtype');

  /// Returns the size, in bytes, of the tensor data.
  int get length => _data.length;

  /// Returns the shape of the Tensor, i.e., the sizes of each dimension.
  Shape get shape => new Shape.dims(_shape);

  /// Returns the tensor shape vector contained in this vector.
  Shape get asShape => new Shape.dims(asInt64List);

  /// Returns the value in a scalar [String] or `UINT8` tensor.
  Uint8List get asUint8List => _data;

  /// Returns the value in a `INT8` tensor.
  Int8List get asInt8List => new Int8List.view(asUint8List.buffer);

  /// Returns the value in a `INT16` tensor.
  Int16List get asInt16List => new Int16List.view(asUint8List.buffer);

  /// Returns the value in a `INT32` tensor.
  Int32List get asInt32List => new Int32List.view(asUint8List.buffer);

  /// Returns the value in a `INT64` tensor.
  Int64List get asInt64List => new Int64List.view(asUint8List.buffer);

  /// Returns the value in a `UINT16` tensor.
  Uint16List get asUint16List => new Uint16List.view(asUint8List.buffer);

  /// Returns the value in a `UINT32` tensor.
  Uint32List get asUint32List => new Uint32List.view(asUint8List.buffer);

  /// Returns the value in a `UINT64` tensor.
  Uint64List get asUint64List => new Uint64List.view(asUint8List.buffer);

  /// Returns the value in a `FLOAT` tensor.
  Float32List get asFloat32List => new Float32List.view(asUint8List.buffer);

  /// Returns the value in a `DOUBLE` tensor.
  Float64List get asFloat64List => new Float64List.view(asUint8List.buffer);

  /// Returns the value of an integer tensor of arbitrary type.
  int get asInt {
    switch (dtype) {
      case DataType.DT_INT8:
        return asInt8;
      case DataType.DT_INT16:
        return asInt16;
      case DataType.DT_INT32:
        return asInt32.toInt();
      case DataType.DT_INT64:
        return asInt64.toInt();
      case DataType.DT_UINT8:
        return asUint8;
      case DataType.DT_UINT16:
        return asUint16;
      case DataType.DT_UINT32:
        return asUint32;
      case DataType.DT_UINT64:
        return asUint64;
      default:
        throw new ArgumentError('Not an integer type: $dtype');
    }
  }

  /// Returns the value of a float tensor of arbitrary type.
  double get asFloat {
    switch (dtype) {
      case DataType.DT_FLOAT:
        return asFloat32;
      case DataType.DT_DOUBLE:
        return asFloat64;
      default:
        throw new ArgumentError('Not a float/double type: $dtype');
    }
  }

  /// Returns the value of an integer vector tensor of arbitrary type.
  List<int> get asIntList {
    switch (dtype) {
      case DataType.DT_INT8:
        return asInt8List;
      case DataType.DT_INT16:
        return asInt16List;
      case DataType.DT_INT32:
        return asInt32List;
      case DataType.DT_INT64:
        return asInt64List;
      case DataType.DT_UINT8:
        return asUint8List;
      case DataType.DT_UINT16:
        return asUint16List;
      case DataType.DT_UINT32:
        return asUint32List;
      case DataType.DT_UINT64:
        return asUint64List;
      default:
        throw new ArgumentError('Not an integer type: $dtype');
    }
  }

  /// Returns the value of an integer vector tensor of arbitrary type.
  List<double> get asFloatList {
    switch (dtype) {
      case DataType.DT_FLOAT:
        return asFloat32List;
      case DataType.DT_DOUBLE:
        return asFloat64List;
      default:
        throw new ArgumentError('Not a float type: $dtype');
    }
  }

  String toString() {
    return 'Tensor { dtype: ' +
        dtype.toString() +
        ', shape: ' +
        shape.toString() +
        ', data: ' +
        asUint8List.toString() +
        ' }';
  }
}

const List<DataType> intTypes = const [
  DataType.DT_INT8,
  DataType.DT_INT16,
  DataType.DT_INT32,
  DataType.DT_INT64,
  DataType.DT_UINT8,
  DataType.DT_UINT16,
  DataType.DT_UINT32,
  DataType.DT_INT64,
];
const List<DataType> floatTypes = const [DataType.DT_DOUBLE, DataType.DT_FLOAT];
