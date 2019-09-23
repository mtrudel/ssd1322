defmodule SSD1322 do
  @moduledoc """
  This module provides a serialized wrapper around a SSD1322.Device
  """

  use GenServer

  def start_link(args \\ []) do
    name = args |> Keyword.get(:name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  def display_on(pid) do
    GenServer.call(pid, :display_on)
  end

  def display_off(pid) do
    GenServer.call(pid, :display_off)
  end

  def contrast(pid, contrast \\ 0xFF) do
    GenServer.call(pid, {:contrast, contrast})
  end

  def clear(pid, grey \\ 0x00) do
    GenServer.call(pid, {:clear, grey})
  end

  def draw(pid, bitmap) do
    GenServer.call(pid, {:draw, bitmap})
  end

  def draw(pid, bitmap, {x, y}, {w, h}) do
    GenServer.call(pid, {:draw, bitmap, {x, y}, {w, h}})
  end

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
