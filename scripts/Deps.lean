import CriticalValues.Ledger
open Lean

run_cmd do
  let env ← Lean.getEnv
  let txt ← IO.FS.readFile "/tmp/toks.txt"
  let mut rows : Array (Name × Name) := #[]
  for line in txt.splitOn "\n" do
    let s := line.trim
    if s.isEmpty then continue
    let n := s.toName
    -- try the bare name and the Polynomial-namespaced form
    for cand in [n, `Polynomial ++ n, `Int ++ n, `Nat ++ n] do
      if let some _ := env.find? cand then
        if let some m := env.getModuleFor? cand then
          if (`Mathlib).isPrefixOf m then rows := rows.push (cand, m)
  let sorted := rows.qsort (fun a b => toString a.2 ++ toString a.1 < toString b.2 ++ toString b.1)
  IO.println s!"MATHLIB_NAMES {sorted.size}"
  for (c, m) in sorted do IO.println s!"{c}\t{m}"
