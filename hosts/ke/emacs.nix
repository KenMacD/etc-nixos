{
  config,
  pkgs,
  ...
}: {
  # TODO: The different modes (like fish-mode) should probably be
  # using new 'treesitter' modes, but someone still has to write
  # a mode. See: https://news.ycombinator.com/item?id=37494595
  environment.systemPackages = with pkgs;
  with config.boot.kernelPackages; [
    (tree-sitter.withPlugins (_: tree-sitter.allGrammars))
    #    tree-sitter
    #    tree-sitter.allGrammars
    #    emacs30-pgtk
    #    TODO: something like:
    # tree-sitter.withPlugins (_: allGrammars)
    ((emacsPackagesFor (pkgs.emacs30-pgtk.override {
        withTreeSitter = true;
        #      tree-sitter = (pkgs.tree-sitter.withPlugins (_: tree-sitter.allGrammars));
      }))
      .emacsWithPackages (epkgs:
        with epkgs; [
          avy
          compat
          consult
          corfu
          corfu-terminal
          dash
          embark
          embark-consult
          evil
          fish-mode
          git-commit
          json-mode
          kind-icon
          magit
          magit-section
          marginalia
          orderless
          popon
          svg-lib
          transient
          treesit-grammars.with-all-grammars
          treesit-auto
          #(treesit-grammars.with-grammars (p: builtins.attrValues p))
          #treesit-grammars.with-all-grammars
          #tree-sitter.allGrammars
          vertico
          which-key
          with-editor
          yaml-mode
        ]))
  ];
}
