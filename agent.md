# Descrizione del progetto
Questo progetto è per un database SQLite per un launcher di source port Doom.
Deve essere il più generico possibile.

# Struttura del database
## regole di nomenclatura
- i nomi devono essere in inglese
- i nomi devono essere in minuscolo
- i nomi devono essere al singolare, la nomenclatura descrive l'entità singola
- i nomi devono essere separati da un trattino basso
- le FK devono essere definite come nome_entità_id ed essere auto incrementalte come PK
- Dove necessario impostare una UK (Unique Key) , per esempio, il nome del port è univoco.

## Entità richieste
- port : contiene la configurazione del source port
- file : il posto dove contenere tuttti i files relativi al file system (non solo wad, ma anche pk3 ed altri)
- iwad : contiene i percorsi degli IWAD (non solo iwad, ma anche ipk3 per i port che lo supportano)
- profile: i profili dove posso aggiungere 1 iwad, n files ed eventuali parametri aggiuntivi
se necessario crea tabelle aggiuntive, sapendo che serve anche l'ordine di caricamento dei
files aggiuntivi, iwad è sempre alla prima posizione (0-based)
- dmflags: una gestione per le varie tipologie di dmflags di GZ/UZDoom e Zandronum, questi devono essere gestiti per port.

Dovesse servire crea pure eventuali tabelle mancanti per collegare correttamente le varie entità.

# Output richiesto
- Un file .sql con la creazione delle tabelle