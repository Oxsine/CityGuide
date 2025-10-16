// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_marker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapMarkerAdapter extends TypeAdapter<MapMarker> {
  @override
  final int typeId = 0;

  @override
  MapMarker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapMarker(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      createdAt: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MapMarker obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
