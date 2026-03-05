# Data Encoding and Transmission Format of the thermometry chain heads from SchwaRTech 

## Transmission via Iridium RockBLOCK (SBD)

The sensor data are transmitted using **Iridium RockBLOCK Short Burst Data (SBD)** messages.

At the device level, the payload is sent as a **binary byte stream**. Each measurement record is therefore a sequence of raw bytes.

Example (binary payload shown as a hex dump):

```
0000: 35 9d b2 fc db 0a 46 6c 34 e6 df 34 f5 4e fd 0e
0016: 0a 45 fe 35 03 20 34 fb 68 fc a0 0a 46 9e 35 d0
0032: 8d 35 e5 f5 fc c1 0a 45 75 36 f6 e1 36 de e2 fc
```

Each pair of hex characters represents **one byte (8 bits)**.

### Conversion to HEX for delivery

When RockBLOCK delivers the message through:

- the **RockBLOCK web portal**
- the **HTTP callback API**
- **email delivery**

the binary payload is encoded as a **hexadecimal string** so that it can be transmitted safely as text.

Example:

Binary bytes

```
35 9d b2 fc db 0a 46 6c
```

become the payload string

```
359db2fcdb0a466c
```

The decoder implemented in this repository operates on this **hex representation of the binary payload**.

---

# Payload Structure

Each measurement record is encoded as a **concatenation of fixed-length hexadecimal fields**.

There are **no separators** between fields.  
In the provided code, the **field order is defined by a schema string** used by the decoder.

Example schema:

```
time_unix adc_temp n1.ntc1 n1.ntc2 n1.gnd n1.pressure battery_mv
```

The decoder reads the hex string sequentially according to this schema.

---

# Integer Encoding

## Unsigned integers

Some values are encoded as **unsigned integers**.

| Field | Size | Description |
|------|------|-------------|
| `time_unix` | 8 hex chars (4 bytes) | Unix time (seconds since 1970-01-01 UTC) |
| `battery_mv` | 4 hex chars (2 bytes) | Battery voltage value |

Unsigned hex values are converted using a robust parser (`hex_to_uint`) to avoid overflow issues with 32-bit integers.

---

## Signed integers (two's complement)

Most sensor values are encoded using **two's complement signed integers**.

| Field | Size | Encoding |
|------|------|-----------|
| `adc_temp` | 6 hex chars (3 bytes) | signed 24-bit |
| `*.ntc1` | 6 hex chars | signed 24-bit |
| `*.ntc2` | 6 hex chars | signed 24-bit |
| `*.pressure` | 6 hex chars | signed 24-bit |
| `*.testSB` | 6 hex chars | signed 24-bit |
| `*.gnd` | 4 hex chars | signed 16-bit |

Decoding rule:

1. Convert the hex block to unsigned integer `v`
2. If `v ≥ 2^(bits-1)` then

```
value = v - 2^bits
```

otherwise

```
value = v
```

---

# Example Field Layout

For a simplified schema

```
time_unix adc_temp n1.ntc1 n1.ntc2 n1.gnd n1.pressure battery_mv
```

the payload is interpreted as:

| Field | Hex chars | Bytes |
|------|------|------|
| time_unix | 8 | 4 |
| adc_temp | 6 | 3 |
| n1.ntc1 | 6 | 3 |
| n1.ntc2 | 6 | 3 |
| n1.gnd | 4 | 2 |
| n1.pressure | 6 | 3 |
| battery_mv | 4 | 2 |

All blocks are concatenated into a single hex string.

---

# Decoding

Decoding is performed with:

```r
decode_hex_line(schema, hex_string)
```

This function:

1. Splits the schema into field names
2. Reads the corresponding number of hex characters for each field
3. Converts the hex block to an integer according to the field type
4. Returns a named list of decoded values

If the payload contains additional characters beyond the schema definition, a warning is generated.

---

# Conversion to Physical Units (Level-2 Processing)

The decoded integer values represent **raw sensor counts**.

These can be converted to physical units using calibration functions:

| Quantity | Conversion |
|------|------|
| ADC temperature | `adc2temp(count)` |
| NTC temperature | `NTCcounts2temp(count)` |
| pressure | `pressure_counts / 10000` → hPa |
| timestamp | `as.POSIXct(time_unix, origin="1970-01-01", tz="UTC")` |

---
