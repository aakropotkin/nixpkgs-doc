{

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.utils.url = "github:numtide/flake-utils";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";


/* -------------------------------------------------------------------------- */
  
  outputs = { self, nixpkgs, utils }: let
    inherit (utils.lib) eachDefaultSystemMap;
  in {

/* -------------------------------------------------------------------------- */

    packages = eachDefaultSystemMap ( system: {

      nixpkgsDoc = nixpkgs.htmlDocs.nixpkgsManual.overrideAttrs ( prev: {
        nativeBuildInputs = ( prev.nativeBuildInputs or [] ) ++ [
          nixpkgs.legacyPackages.${system}.texinfo
        ];
        postBuild = ''
          mkdir texi info
          sed 's/\(<title><function>\)lib\.[^.]*\.\?\([^.<][^<]\+<\/function><\/title>\)/\1\2/'  \
            manual-full.xml > manual-full-nodots.xml
          pandoc -t texinfo -f docbook -o texi/nixpkgs.texi  \
                 manual-full-nodots.xml
          makeinfo --force -o info texi/nixpkgs.texi
        '';
        installPhase = ''
          runHook preInstall
          ${prev.installPhase}
          runHook postInstall
        '';
        postInstall = ''
          cp -pr --reflink=auto -- info "$out/share/"
        '';
      } );

      default = self.packages.${system}.nixpkgsDoc;

    } );


/* -------------------------------------------------------------------------- */
    
    overlays.nixpkgsDoc = final: prev: {
      inherit (self.packages.${prev.system}) nixpkgsDoc;
    };
    overlays.default = self.overlays.nixpkgsDoc;


/* -------------------------------------------------------------------------- */

  };
}
