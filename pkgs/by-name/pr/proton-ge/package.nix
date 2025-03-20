{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  steamDisplayName ? "GE-Proton",
}:
stdenv.mkDerivation rec {
  pname = "proton-ge";
  version = "GE-Proton9-26";

  src = fetchFromGitHub {
    owner = "GloriousEggroll";
    repo = "proton-ge-custom";
    rev = version;
    sha256 = "sha256-Kr3JdI86rzRlKgHxKH2FNjEI29BiCaF78Ks6NhOO8mY=";
    fetchSubmodules = true;
  };

  outputs = [
    "out"
    "steamcompattool"
  ];

  nativeBuildInputs = with pkgs; [
    docker
    which
  ];

  buildPhase = ''
    export HOME=$(pwd)
    dockerd-rootless&
    bash ./patches/protonprep-valve-staging.sh
    mkdir build && cd build
    bash ../configure.sh --build-name=Proton-GE
    make redist
  '';
  
  installPhase = ''
    runHook preInstall

    # Make it impossible to add to an environment. You should use the appropriate NixOS option.
    # Also leave some breadcrumbs in the file.
    echo "${pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    tar -xvzf build/Proton-GE.tar.gz
    ln -s $src/build/Proton-GE/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/build/Proton-GE/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "${version}" "${steamDisplayName}"
  '';

  meta = {
    description = ''
      Compatibility tool for Steam Play based on Wine and additional components.

      (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
    '';
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      dynamicgoose
    ];
  };
}
