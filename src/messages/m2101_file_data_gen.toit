import ..protocol as protocol

// Auto generated class for protocol message
class FileData extends protocol.Data:

  static MT := 2101
  static MT_NAME := "FileData"

  static FILE-TYPE := 1
  static FILE-TYPE_ESP32-FIRMWARE := 1

  static FILE-TYPE_STRINGS := {
    1: "ESP32 Firmware",
  }

  static file-type-from-int value/int -> string:
    return FILE-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static FILE-ID := 2
  static CHUNK := 3
  static CHUNK-SIZE := 4
  static TOTAL-SIZE := 5
  static TOTAL-CHUNKS := 6
  static STATUS := 7
  static TARGET-ADDRESS := 8
  static MD5 := 9
  static CHUNK-COUNT := 10
  static PAYLOAD := 129

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --file-type/int?=null --file-id/int?=null --chunk/int?=null --chunk-size/int?=null --total-size/int?=null --total-chunks/int?=null --status/int?=null --target-address/int?=null --md5/ByteArray?=null --chunk-count/int?=null --payload/ByteArray?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if file-type != null: data.add-data-uint FILE-TYPE file-type
    if file-id != null: data.add-data-uint FILE-ID file-id
    if chunk != null: data.add-data-uint CHUNK chunk
    if chunk-size != null: data.add-data-uint CHUNK-SIZE chunk-size
    if total-size != null: data.add-data-uint TOTAL-SIZE total-size
    if total-chunks != null: data.add-data-uint TOTAL-CHUNKS total-chunks
    if status != null: data.add-data-uint STATUS status
    if target-address != null: data.add-data-uint TARGET-ADDRESS target-address
    if md5 != null: data.add-data MD5 md5
    if chunk-count != null: data.add-data-uint CHUNK-COUNT chunk-count
    if payload != null: data.add-data PAYLOAD payload
    return data

  /**
   * Creates a File Data message without a specific method.
   *
   * This is used for messages that don't require a specific method type
   * (like GET, SET, SUBSCRIBE) but still need to carry data.
   *
   * Parameters:
   * - data: Optional protocol.Data object containing message payload
   *
   * Returns: A Message ready to be sent
   */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
   * Creates a GET Request message for File Data.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * File class. 1 = ESP32 firmware.
   *
   * Valid values:
   * - FILE-TYPE_ESP32-FIRMWARE (1): ESP32 Firmware
   */
  file-type -> int:
    return get-data-uint FILE-TYPE

  /**
   * Firmware/file id or version requested by the device.
   */
  file-id -> int:
    return get-data-uint FILE-ID

  /**
   * Chunk index, 0-based.
   */
  chunk -> int:
    return get-data-uint CHUNK

  /**
   * Requested chunk size in bytes. Initial ESP32 OTA implementation requests 1024-byte chunks.
   */
  chunk-size -> int:
    return get-data-uint CHUNK-SIZE

  /**
   * Total file size in bytes.
   *
   * Unit: byte
   */
  total-size -> int:
    return get-data-uint TOTAL-SIZE

  /**
   * Total number of chunks in the file.
   */
  total-chunks -> int:
    return get-data-uint TOTAL-CHUNKS

  /**
   * Device/server status for file transfer (0=ok or need data, 2=error).
   */
  status -> int:
    return get-data-uint STATUS

  /**
   * Target module flash address, when relevant.
   */
  target-address -> int:
    return get-data-uint TARGET-ADDRESS

  /**
   * 16-byte whole-file MD5, when available.
   */
  md5 -> ByteArray:
    return get-data MD5

  /**
   * Optional number of sequential chunks requested starting from chunk. If omitted, defaults to 1.
   */
  chunk-count -> int:
    return get-data-uint CHUNK-COUNT

  /**
   * Extended-length payload field containing one complete chunk. Field id 129 uses
   * a two-byte little-endian V3 length prefix, so a 1024-byte ESP32 OTA chunk fits
   * in a single field.
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  stringify -> string:
    return {
      "fileType": file-type,
      "fileId": file-id,
      "chunk": chunk,
      "chunkSize": chunk-size,
      "totalSize": total-size,
      "totalChunks": total-chunks,
      "status": status,
      "targetAddress": target-address,
      "md5": md5,
      "chunkCount": chunk-count,
      "payload": payload,
    }.stringify
