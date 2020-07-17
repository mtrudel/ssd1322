defmodule SSD1322 do
  @moduledoc """
  This module provides a serialized wrapper around a SSD1322.Device
  """

  use GenServer

  @doc """
  Starts a connection to an SSD1322 with the given parameters, wrapped in a GenServer to serialize access to the device.
  Returns an `{:ok, pid}` tuple where the pid is passed in to the other functions in this module.

  Options are passed as a keyword list with the following possible values:

  * `spi_connection_opts`: A nested keyword list containing any of the possible 
  values below:
      * `spi_dev`: The name of the spi device to connect to. Defaults to `spidev0.0`
      * `dc_pin`: The GPIO pin number of the line to use for D/C select. Defaults to 24
      * `reset_pin`: The GPIO pin number of the line to use for reset. Defaults to 25
  * `conn`: A pre-existing SSD1322.SPIConnection struct, if you already have one
  * `width`: The width of the display in pixels. Must be a multiple of 4. Defaults to 256
  * `height`: The height of the display in pixels. Defaults to 64
  """
  def start_link(args \\ []) do
    name = args |> Keyword.get(:name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  Issues a reset to the SSD1322 device.
  """
  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  @doc """
  Turns the display on.
  """
  def display_on(pid) do
    GenServer.call(pid, :display_on)
  end

  @doc """
  Turns the display off.
  """
  def display_off(pid) do
    GenServer.call(pid, :display_off)
  end

  @doc """
  Sets the contrast of the display. Valid values range from 0 (lowest contrast) to 255 (highest contrast).
  """
  def contrast(pid, contrast \\ 0xFF) do
    GenServer.call(pid, {:contrast, contrast})
  end

  @doc """
  Clears the display to the specified grey level. 
  Valid values for `grey` are from 0 (black) to 15 (whatever colour your display is). Defaults to 0.
  """
  def clear(pid, grey \\ 0) do
    GenServer.call(pid, {:clear, grey})
  end

  @doc """
  Draws the specified bitmap. The bitmap must be in packed 4-bit greyscale format and the size
  of the full display as configured. For pixel format details see SSD1322.Device.draw.
  """
  def draw(pid, bitmap) do
    GenServer.call(pid, {:draw, bitmap})
  end

  @doc """
  Draws the specified bitmap at coordinates `{x, y}`. The bitmap must be in packed 4-bit greyscale format and the size
  corresponding to the specified width & height. For pixel format details see SSD1322.Device.draw.

  Both `x` and `width` must be a multiple of 4.
  """
  def draw(pid, bitmap, {x, y}, {w, h}) do
    GenServer.call(pid, {:draw, bitmap, {x, y}, {w, h}})
  end

  @doc false
  def init(args) do
    {:ok, SSD1322.Device.init(args)}
  end

  def handle_call(:reset, _from, device) do
    {:reply, SSD1322.Device.reset(device), device}
  end

  def handle_call(:display_on, _from, device) do
    {:reply, SSD1322.Device.display_on(device), device}
  end

  def handle_call(:display_off, _from, device) do
    {:reply, SSD1322.Device.display_off(device), device}
  end

  def handle_call({:contrast, contrast}, _from, device) do
    {:reply, SSD1322.Device.contrast(device, contrast), device}
  end

  def handle_call({:clear, grey}, _from, device) do
    {:reply, SSD1322.Device.clear(device, grey), device}
  end

  def handle_call({:draw, bitmap}, from, device) do
    handle_call({:draw, bitmap, {0, 0}, {device.width, device.height}}, from, device)
  end

  def handle_call({:draw, bitmap, {x, y}, {width, height}}, _from, device) do
    {:reply, SSD1322.Device.draw(device, bitmap, {x, y}, {width, height}), device}
  end
end
