Baru aja kelar research gimana caranya bikin agent yang bisa kontrol android device, kayak OpenClaw atau Hermes. Dan akhirnya berhasil, dengan use case automate aplikasi KlxkIndxmaret dan Alxagxft buat cariin produk lalu masukin ke cart.

Sebenarnya core yang kita butuhin cuma ada 2 komponen:

1. LLM/Orchestrator: otak dan mata-nya
2. AccessibilityService: tangannya

Sederhananya, orchestrator yang decide apa yang harus dilakukan (misalnya close banner, dll). Terus accessibility dan tooling yang eksekusi: tap screen, swipe screen, screenshot, dan seterusnya.

Untuk LLM yang dicoba: hermes-termux dan agentic harness (claude code). Tooling-nya pakai SuperMonster003/AutoJs6 dan raulvidis/hermes-android. Claude code + AutoJs6 dipakai buat Indxmaret, sedangkan hermes-termux buat Alxagxft.

Sebenarnya, buat automasi kedua app tadi, best practice-nya bisa via browser aja ketimbang mobile app-nya langsung. Tapi yang di-research di sini bukan itu, melainkan: gimana caranya agent bisa hidup di android device kita, dan gimana cara ngajarinnya.

Singkatnya, flow cara ngajarin agent-nya kira-kira gini:

1. Suruh agent define window/view-area dari app-nya. Misalnya split screen, tentuin lokasi app-nya ada di mana buat dapetin "bounds"-nya, karena tiap device pasti beda.
2. Cari element-nya satu-satu. Suruh agent count dari bounds area-nya aja. Kadang pas debugging, agent perlu "melihat" lewat screenshot (vision). Nah, buat hemat cost analisa image, kita bisa suruh agent-nya screenshot partial. Misalnya mau locate posisi search bar, tinggal bilang dari top screenshot beberapa px ke bawah aja.
3. Pas udah dapet posisi element-nya, baru deh instruksiin suruh tap, typing, dan seterusnya.
4. Dan seterusnya. Workflow ini disimpan ke structured data, misalnya JSON.

Nggak harus selalu pakai vision. AccessibilityService juga cukup powerful buat locate posisi element yang mau kita cari. Simplenya kayak dia bisa cari posisi teks, button, dll ada di mana. Semacam inspect element lah sepertinya (cmiiw).

Oh iya, kalau pakai hermes-termux, dia bisa belajar sendiri. Cuma pastinya cost-nya kemungkinan bakal mahal buat lakuin looping trial & error. Jadi kalau mau hemat cost, prefer bikin manual pakai agent biasa.

Cuma perlu diperhatiin ya. Allow accessibility artinya ngizinin AI buat lakuin banyak hal di device kita. Bayangin kalau agent-nya bisa jalan sendiri, terus checkout item terus-terusan secara otomatis. Atau baca stored session dan akses banking app, haha.

Findings:

1. Kita butuh model yang support vision buat debugging.
2. Cost penggunaan vision dihitung dari dimensi imagenya. Kirain awalnya tergantung content imagenya, misalnya screenshot dominan text dan background polos, cost-nya bakal lebih murah. Ternyata engga.
3. Buat hemat cost LLM-nya, jangan selalu pakai vision. Usahain pakai AccessibilityService aja, 0 cost.
4. Tentuin batasan. Suruh agent cuma buat hal-hal yang nggak sensitif kayak checkout atau payment.
5. Tested di Xiaomi (HyperOS) dan Huawei (HarmonyOS)
