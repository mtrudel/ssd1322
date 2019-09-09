# SSD1322

This package provides an interface for controlling OLED displays using the common 
[SSD1322](https://www.newhavendisplay.com/app_notes/SSD1322.pdf) chipset, as 
available [here](https://www.aliexpress.com/item/32988174566.html) (or many other vendors).
In addition to supporting a number of bitmap formats for display, you can also control various
aspects of the display such as contrast values, enabling / disabling the display and other tasks.

## Hardware

This library requires a 4 wire SPI connection to the display board, in addition to two GPIO lines. 
All connections are made using the [Elixir Circuits](https://elixir-circuits.github.io) library.

If using this library via Nerves and wiring your hardware up in the manner described in the 'Putting it together' section of [this article](https://www.balena.io/blog/build-a-raspberry-pi-powered-train-station-oled-sign-for-your-desk/),
the default values will be sufficient. In other situations, you may need to explicitly set hardware
parameters as detailed in the next section.

## Usage

Common usage looks like so:

```
# Initialize your connection
{:ok, session} = SSD1322.connect()

# You can also override a bunch of options if needed:
{:ok, conn} = SSD1322.SPIConnection.init(spi_dev: "spidev0.0", dc_pin: 24, reset_pin: 25)
{:ok, session} = SSD1322.connect(conn: conn, width: 256, height: 64)

# Display the image defined by data. data is a binary containing row-wise 
# 4-bit greyscale pixel data in linear order. It follows that there data is
# W x H / 2 bytes long. Check out github.com/mtrudel/ex_paint for a library that
# can produce this format with little effort
SSD1322.draw(session, data)

# You can also turn the display on and off
display_on(session)
display_off(session)

# Set the contrast to a value between 0 and 255
contrast(session, contrast)

# Clear the display to a given grey (black by default)
clear(session, grey \\ 0x00)

# Or reset the connection if something goes wrong
reset(session)
```

Note that although this library serializes access for callers sharing a single connection instance, 
neither this library nor the underlying Elixir Circuits library provide any protection against multiple
concurrent access to an attached display by across multiple connection instances.

## Installation

This package can be installed by adding `ssd1322` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ssd1322, "~> 0.1.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/ssd1322](https://hexdocs.pm/ssd1322).

