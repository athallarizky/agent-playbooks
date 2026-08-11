Terkadang saat kita kerja pakai GitHub, aktivitas kerja kita tersebar di mana-mana.

Ada commit di satu repo, PR di repo lain, issue yang diupdate, lalu review yang nyebar di beberapa tempat. Karena reporting di Kitabisa juga nggak daily, seringnya kita baru kepikiran pas ditanya:

- Kemarin ngerjain apa aja?
- PR yang "X" udah di-merge belum?
- Fitur "X" kemarin masuk di PR yang mana?

Akhirnya kepikiran untuk bikin tools yang bisa bantu summarize aktivitas harian yang ada di GitHub, seperti:

- Created / Updated Issue
- Created / Updated / Reviewed Pull Request
- Created Commit

Toolsnya sebenarnya simple. Tinggal pakai `github-cli`, lalu AI agent bisa langsung akses lewat terminal. User cukup login dulu pakai `gh auth login`, lalu tinggal tanya ke agent:

"Eh, di tanggal X kemarin, apa yang udah dikerjain ya?"

Nanti agentnya bakal akses GitHub API, ambil history aktivitas dari user yang sudah login sebelumnya, lalu bikin ringkasan dari semua pekerjaan yang terjadi di tanggal itu.

Kalau mau dibuat sedikit lebih advance, tools ini juga bisa dijadikan daily automation. Bisa pakai cronjob, n8n, OpenClaw, Hermes Agent, atau sesimpel pakai Codex / Cowork automation.

Dengan adanya tools ini, kita jadi lebih gampang buat track apa yang sudah kita kerjain. Bukan cuma enak buat reporting, tapi juga jadi evidence yang lebih jelas buat ngukur matriks atau KPI kerja.
