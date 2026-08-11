Belakangan ini sering delegate task ke AI, apalagi pas iseng bikin project fullstack end-to-end.

Awalnya masih asal-asalan, alhasil:
- banyak issue, banyak debugging
- harus prompting berkali-kali biar sesuai
- context window cepet penuh, responnya jadi halu 😅

Pernah coba plugin/skills/tools open source, tapi ujungnya overkill — boros token & context lagi.

Akhirnya nemu workflow personal yang cocok buat develop project baru dari scratch. Entah namanya apa, tapi biar simple kita sebut aja:

**Sprint Driven Development**, haha.

Cara implementasinya simple: di tiap project, siapin direktori `docs`.

```text
docs/
  sprint-<x>/
    reports/
    rca/           (optional)
    resources/     (optional)
    plan.md
    tasks.md
    final-report.md
    AGENTS.md      (optional)
```

Workflow-nya kira-kira gini:

1. Tiap sprint fokus ke specific goal. Misal sprint-1 slicing UI, sprint-2 backend, sprint-3 integrate, dst.
2. Tiap sprint, instruksikan agent ikut aturan: minimal bikin plan, tasks, reports, dan final-report.

Detail tiap file-nya:

- `plan.md` — masuk plan mode, agent bikin planning-nya dulu. Butuh banyak user-loop: diskusi bareng agent sampai arahnya bener.
- `tasks.md` — setelah plan di-review, pecah tasks jadi sekecil mungkin, susun per phase.
- `reports/` — agent generate report tiap phase: apa yang dibuat, findings, how to run. Dari sini kita bisa decide mau tes manual per phase atau nggak.
- `rca/` — kalau ada issue, suruh LLM solve plus kasih RCA-nya. Jadi kalau issue sama muncul lagi nanti, tinggal refer ke sini.
- `resources/` — acuan/dokumentasi buat sprint berikutnya. Misal sprint-2 bikin `api-contract.md`, biar pas sprint-3 integrate agent tinggal mention ini.
- `AGENTS.md` — instruksi buat agent sprint berikutnya. Misal backend selesai → Agent di Sprint 2 menjelaskan flow integrasi (termasuk kasus khusus, mis. endpoint chaining, edge cases)
- `final-report.md` — rangkuman hasil sprint biar human dapet overview. Bisa dipake buat compact context kalau mau lanjut sprint berikutnya atau debugging di session yang sama.

Intinya, semua kerjaan ke-track: plan, checkpoint task, reports per phase, RCA, resource, final report, sampai instruksi buat agent sprint berikutnya.

Efeknya bukan cuma rapi — gampang juga buat pindah session, atau delegate task/sprint ke agent & model lain.

Udah tested pindah tools (commandcode, claude code, opencode), gonta-ganti model & session. Semua tetep bisa lanjutin task tanpa harus jelasin dari awal.

Tips: pas bikin plan & tasks, pakai model reasoning/thinking (opus, glm5.2, deepseek v4 pro). Selama dua file ini udah oke, implementasi pakai model murah pun aman.
