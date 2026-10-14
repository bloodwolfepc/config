{
  boot.kernelModules = [
    "snd_virmidi"
    "snd_seq_dummy"
  ];
  boot.extraModprobeConfig = ''
    options snd_seq_dummy ports=4
    options snd_virmidi midi_devs=1
  '';
}
