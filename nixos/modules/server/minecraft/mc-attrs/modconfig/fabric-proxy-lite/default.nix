{ pkgs, ... }: {
  fabric-proxy-lite = pkgs.writeTextFile {
    name = "FabricProxy-Lite.toml";
    text = ''
      hackOnlineMode = true
      hackEarlySend = false
      hackMessageChain = true
      disconnectMessage = "This server requires you to connect with Velocity."
      secret = "ExampleForwardingSecret"
    '';
  };
}

