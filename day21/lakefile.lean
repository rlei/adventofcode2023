import Lake
open Lake DSL

package «day21» where
  -- add package configuration options here

@[default_target]
lean_exe «prob1» where
  root := `prob1

lean_exe «prob2» where
  root := `prob2
