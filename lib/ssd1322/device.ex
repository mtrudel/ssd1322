defmodule SSD1322.Device do
  @moduledoc """
  This module provides a high-level interface to control and display content on
  a SSD1322 based OLED display. 

  Note that this module is stateless - there is no protection here at all for 
  concurrent access

  For details regarding the magic values used herein, consult the [SSD1322 datasheet](https://www.newhavendisplay.com/app_notes/SSD1322.pdf)
  """

  defstruct conn: nil, width: 0, height: 0

  @gdram_row_width 480

  alias SSD1322.SPIConnection

  def init(opts \\ []) do
    spi_connection_opts = opts |> Keyword.get(:spi_connection_opts, [])

    session = %__MODULE__{
      conn: Keyword.get(opts, :conn, SPIConnection.init(spi_connection_opts)),
      width: Keyword.get(opts, :width, 256),
      height: Keyword.get(opts, :height, 64)
    }

    reset(session)
    clear(session)
    contrast(session, 255)
    display_on(session)
    session
  end

  def reset(%__MODULE__{conn: conn}) do
    SPIConnection.reset(conn)
    SPIConnection.command(conn, <<0xFD>>, <<0x12>>)
    SPIConnection.command(conn, <<0xA4>>)
    SPIConnection.command(conn, <<0xB3>>, <<0xF2>>)
    SPIConnection.command(conn, <<0xCA>>, <<0x3F>>)
    SPIConnection.command(conn, <<0xA2>>, <<0x00>>)
    SPIConnection.command(conn, <<0xA1>>, <<0x00>>)
    SPIConnection.command(conn, <<0xA0>>, <<0x14, 0x11>>)
    SPIConnection.command(conn, <<0xB5>>, <<0x00>>)
    SPIConnection.command(conn, <<0xAB>>, <<0x01>>)
    SPIConnection.command(conn, <<0xB4>>, <<0xA0, 0xFD>>)
    SPIConnection.command(conn, <<0xC7>>, <<0x0F, 0xB9>>)
    SPIConnection.command(conn, <<0xB1>>, <<0xF0>>)
    SPIConnection.command(conn, <<0xD1>>, <<0x82, 0x20>>)
    SPIConnection.command(conn, <<0xBB>>, <<0x0D>>)
    SPIConnection.command(conn, <<0xB6>>, <<0x08>>)
    SPIConnection.command(conn, <<0xBE>>, <<0x00>>)
    SPIConnection.command(conn, <<0xA6>>)
    SPIConnection.command(conn, <<0xA9>>)
  end

  def display_on(%__MODULE__{conn: conn}) do
    SPIConnection.command(conn, <<0xAF>>)
  end

  def display_off(%__MODULE__{conn: conn}) do
    SPIConnection.command(conn, <<0xAE>>)
  end

  def contrast(%__MODULE__{conn: conn}, contrast) do
    SPIConnection.command(conn, <<0xC1>>, <<contrast::8>>)
  end

  def clear(%__MODULE__{width: width, height: height} = device, grey \\ 0) do
    draw(device, :binary.copy(<<grey::4, grey::4>>, div(width * height, 2)), {0, 0}, {width, height})
  end

  # This function does not perform any clipping or validation on the given binary other than to  other than to 
  # validate that its x offset and width are both multiples of 4
  def draw(%__MODULE__{conn: conn, width: display_width}, binary, {x, y}, {width, height}) do
    if rem(x, 4) != 0, do: raise("Cannot draw when x is not divisible by 4 (x=#{x})")
    if rem(width, 4) != 0, do: raise("Cannot draw when width is not divisible by 4 (width=#{width})")

    # Memory row widths don't know anything about the actual number of pixels on the device. The SSD1322 chip
    # supports displays up to 480 pixels wide, and if a display is narrower than that its pixels are centered in the
    # memory row. As a consequence, pixel column 0 on the display is actually (480 - display_width) / 2 bytes into the 
    # row.
    display_zero = div(@gdram_row_width - display_width, 2)
    offset = display_zero + x

    # GDRAM addresses 16 bit words, and each pixel is 4 bits, so offsets / widths need to divide by 4 
    offset_to_write = div(offset, 4)
    width_to_write = div(width, 4)

    SPIConnection.command(conn, <<0x15>>, <<offset_to_write, offset_to_write + width_to_write - 1>>)
    SPIConnection.command(conn, <<0x75>>, <<y, y + height - 1>>)
    SPIConnection.command(conn, <<0x5C>>, binary)
  end
end
