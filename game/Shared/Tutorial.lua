-- Stable entry point for adventure/lobby. The authored first phase replaces the
-- prototype; historical maps are retained only as regression test fixtures.
return require(if script then script.Parent.PhaseOne else "./PhaseOne")
