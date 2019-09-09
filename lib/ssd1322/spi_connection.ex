defmodule SSD1322.SPIConnection do
  @moduledoc """
  Provides a high-level hardware interface to SSD1322-style SPI interfaces.
  """

  defstruct spi: nil, dc: nil, reset: nil

  @data_chunk_size 4096

  @doc """
  Initializes the SPI / GPIO connection to the display, but does not reset it
  or otherwise communicate with it in any way

  Can take an optional keyword list to configure the connection details. Valid keys include:

  * `spi_dev`: The name of the spi device to connect to. Defaults to `spidev0.0`
  * `dc_pin`: The GPIO pin number of the line to use for D/C select. Defaults to 24
  * `reset_pin`: The GPIO pin number of the line to use for reset. Defaults to 25
  """
  def init(opts \\ []) do
    {:ok, spi} = opts |> Keyword.get(:spi_dev, "spidev0.0") |> Circuits.SPI.open(speed_hz: 8_000_000, delay_us: 5)
    {:ok, dc} = opts |> Keyword.get(:dc_pin, 24) |> Circuits.GPIO.open(:output)
    {:ok, reset} = opts |> Keyword.get(:reset_pin, 25) |> Circuits.GPIO.open(:output)

    %__MODULE__{spi: spi, dc: dc, reset: reset}
  end

  @doc """
  Issues a hardware reset to the display
  """
  def reset(%__MODULE__{reset: reset}) do
    Circuits.GPIO.write(reset, 0)
    Circuits.GPIO.write(reset, 1)
  end

  @doc """
  Sends the given command to the display, along with optional data
  """
  def command(%__MODULE__{spi: spi, dc: dc} = conn, command, data \\ nil) do
    Circuits.GPIO.write(dc, 0)
    Circuits.SPI.transfer(spi, command)

    if data do
      data(conn, data)
    end
  end

  @doc """
  Sends data to the display, chunking it into runs of at most `data_chunk_size` bytes
  """
  def data(%__MODULE__{spi: spi, dc: dc}, data) do
    Circuits.GPIO.write(dc, 1)
    data_chunked(spi, data)
  end

  defp data_chunked(spi, data) do
    case data do
      <<head::binary-size(@data_chunk_size), tail::binary>> ->
        Circuits.SPI.transfer(spi, <<head::binary-size(@data_chunk_size)>>)
        data_chunked(spi, tail)

      remainder ->
        Circuits.SPI.transfer(spi, remainder)
    end
  end
end
