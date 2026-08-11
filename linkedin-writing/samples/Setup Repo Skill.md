Dengan adanya AI, sekarang di Kitabisa kita lagi mulai dibiasakan buat nggak terlalu nempel ke satu role aja. Backend bisa bantu pegang task frontend, dan sebaliknya.

Tapi ada satu masalah awal yang cukup sering muncul: 

"gimana cara setup repo yang sebelumnya belum pernah kita sentuh?"

Apalagi kalau repositorinya legacy, tech stack-nya lama, dependency-nya tricky, atau cara run local-nya cuma diketahui beberapa orang aja.

Biasanya bagian ini cukup makan waktu. Bukan karena task-nya sulit, tapi karena harus nanya-nanya dulu:
- pakai versi Node berapa?
- perlu env apa aja?
- service dependency-nya apa?
- kalau error A harus diapain?
- command run-nya yang benar yang mana?

Akhirnya kepikiran: kenapa nggak bikin skill aja untuk tiap repo?

Jadi bukan cuma dokumentasi setup biasa, tapi instruksi yang memang ditulis supaya bisa dieksekusi oleh AI agent. User tinggal bilang ke agent: 

"Tolong setup repo <nama-repo> di port <X>"

Kurang lebih flow-nya seperti ini:

1. Ambil knowledge dari engineer yang familiar dengan repo tersebut
2. Tulis step-by-step cara setup repo
3. Tambahin instruksi kondisional untuk case-case umum
4. Pisahin troubleshooting ke file sendiri
5. Minta agent bantu rapihin jadi skill yang bisa dipakai ulang

Sebenarnya alternatif paling obvious adalah pakai Docker. Tapi kemarin penasaran juga: kira-kira bisa nggak sih repo-repo internal dipasangin skill biar setup local-nya lebih gampang, terutama buat teman-teman yang baru masuk ke area repo tersebut?

Dan ternyata, bisa.

Formatnya dibuat simple:

```text
<repo-name>/
  docs/
    troubleshooting.md
  SKILL.md
  AGENTS.md
```
- `AGENTS.md` - entrypoint untuk masing-masing agent.
- `SKILL.md` - step-by-step setup repo, termasuk instruksi IF-ELSE untuk kondisi tertentu.
- `docs/troubleshooting.md` - daftar kemungkinan error yang sering muncul, penyebabnya, dan cara solve-nya.

Pas dicoba, skill ini bisa dipakai agent untuk setup salah satu repo dari awal sampai berhasil running di local machine. Yang menarik, bahkan ketika dicoba pakai model yang lebih ringan, agent tetap bisa ngikutin instruksinya selama skill-nya cukup jelas. 

Ohiya, kita juga bisa instruksikan agentnya untuk pake 'user-select question' tools supaya agentnya bisa ngasih opsi ke manusia mau ambil action yang mana. 

Contoh casenya misal kita mau: 
(1) setup localhost aja (localhost:3000)
(2) sekalian setup local proxy domain (example.domain.local)

Dengan begini, instalasi repo bisa jadi lebih flexible tergantung kebutuhan user. Mungkin ini belum tentu best practice. Tapi sebagai eksperimen kecil, hasilnya cukup promising.

Dengan skill seperti ini, konteks setup yang biasanya nempel di kepala beberapa engineer bisa dipindahkan jadi reusable instruction. Engineer lain tinggal minta agent menjalankan setup, review langkah-langkahnya, accept command yang perlu dijalankan, lalu fokus ke task utamanya.

Hopefully ini bisa bantu teman-teman engineer yang mulai lebih multirole, supaya saat masuk ke repo yang bukan area sehari-harinya, proses awalnya lebih seamless dan nggak terlalu banyak friction.

Contoh skill-nya aku push disini: 
