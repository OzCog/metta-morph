awk '{gsub("new-space", "new-space ()") gsub(/\(\, /, "(MatchChain ") gsub(/self \(= \(/, "self (\047=def (\047") gsub(/True/, "#t") gsub(/False/, "#f") gsub(/\|\-/, "DERIVE") gsub(/\(\)/, "\047()") gsub(/\(match /, "(Match ") gsub(/\(let /, "(Let ") gsub(/\(let\* /, "(Let\* ") gsub(/\(match /, "(Match ") gsub(/\(case /, "(Case ") gsub(/\(car-atom /, "(car ") gsub(/\(cdr-atom /, "(cdr "); if($0 ~ /^[(]/ && !($0 ~ /^[(][:|=]/)) { gsub(/^[(]/, "!(add-atom \\&self (", $0); $0 = $0 ")" } gsub(/\!\(/, "(! ", $0) gsub(/\(: /, "(Typedef ")}1' $1 > PROGRAM.scm 2> /dev/null
cat mettamorph.scm PROGRAM.scm > RUN.scm
csi -s RUN.scm
