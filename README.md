# SPI implementation in VHDL
Implementation of the Serial Peripheral Interface (SPI) communication protocol using VHDL.



## 📦 Installing libraries

### 🖥️ Installing NVC
1. Install NVC.
```
brew install nvc
```

2. Check NVC's version.
```
nvc --version
```


### 📈 Installing GTKWave
1. Install dependencies.
```
brew install desktop-file-utils shared-mime-info       \
             gobject-introspection gtk-mac-integration \
             meson ninja pkg-config gtk+3 gtk4
```

2. Build GTKWave.
Head to the GitHub folder where you've got all your cloned
repositories and run this:
```
git clone "https://github.com/gtkwave/gtkwave.git"
cd gtkwave
meson setup build && cd build && meson install
```

3. Check GTKWave's version.
```
which gtkwave
```



## 🚀 Running a simulation and visualizing the waveform
To run a simulation and generate the corresponding waveform, execute this command:
```
nvc -a spi_master.vhd spi_master_tb.vhd -e spi_master_tb -r spi_master_tb --wave=waves.vcd
```

To visualize the waveform file of the simulation run, open the file with GTKWave:
```
gtkwave waves.vcd
```
