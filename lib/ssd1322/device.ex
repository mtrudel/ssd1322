defmodule SSD1322.Device do
  @moduledoc """
  This module provides a high-level interface to control and display content on
  a SSD1322 based OLED display. 

  Note that this module is stateless - there is no protection here at all for 
  concurrent access

  For details regarding the magic values used herein, consult the [SSD1322 datasheet](https://www.newhavendisplay.com/app_notes/SSD1322.pdf)
  """

  defstruct conn: nil, width: 0, height: 0

  @gdram_row_width 120

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
    draw(device, :binary.copy(<<grey::4, grey::4>>, div(width * height, 2)))
  end

  def draw(%__MODULE__{conn: conn, width: width, height: height}, binary) do
    # GDRAM writes word-wise (16 bits at a time), and each pixel is 4 bits, so the width in RAM is width/4.
    # We write our pixels inthe the middle of each GDRAM row
    width_to_write = div(width, 4)
    offset = div(@gdram_row_width - width_to_write, 2)

    SPIConnection.command(conn, <<0x15>>, <<offset, offset + width_to_write - 1>>)
    SPIConnection.command(conn, <<0x75>>, <<0, height - 1>>)
    SPIConnection.command(conn, <<0x5C>>, binary)
  end
end
