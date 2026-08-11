Semakin sering baca forum, semakin banyak nemuin repo github yang menarik buat diulik.

Biasanya kalau udah nemuin repo bagus, langkah pertama ya star. Cuma lama-kelamaan list-nya numpuk, dan pas lagi butuh tools tertentu, jadi susah carinya. Pernah ngalamin gitu? 

"Dulu kayaknya pernah star repo tentang tools ini deh, apa ya namanya.." 

terus scroll-scroll list starred dan nggak ketemu-ketemu.

Akhirnya kepikiran bikin tools simpel buat collect starred repo yang bisa diproses pakai LLM, biar gampang cariin tools yang lagi dibutuhkan.

Flow-nya juga singkat:

1. Run script fetch list starred user repo pakai github-cli
2. Simpen di .csv dan tulis di .md
3. Suruh agent summarize/cariin/rekomendasiin toolsnya

Untungnya, starred repo bersifat public. Jadi kita bisa collect starred repo dari user lain juga, tinggal prompt:

"collect <gh-user-name> starred repo"

Hasilnya akan disimpan di:

```
collections/
  <gh-user-name>/
    starred.md
    data.csv
```

Ide-nya, .csv ini nantinya bisa digunakan untuk knowledge base buat RAG atau lainnya. Dan starred.md ini human-readable content buat baca listnya.

Tools ini juga bisa combine list dari beberapa collection user. Tinggal prompt: combine starred from user: a,b,c. Nantinya akan di normalize & dedup, terus datanya di provide langsung.
