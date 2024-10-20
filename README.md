# Gagnasaga um Krúnuleikana

## TL;DR
Þetta verkefni snýst um að safna og greina gögn um konungsríki í Westeros til þess að réttlæta stöðu Dorne sem eitt af konungsríkjunum sjö. Helstu niðurstöður okkar sýndu að fjöldi áhugaverðra staða í Dorne voru jafn margir og meðal konungsríkisins, og flatarmál þess væri það þriðja stærsta.

## Strúktúr
Repo-ið er sett upp eins og hér segir:
- `config.yml`: Inniheldur tengingarupplýsingar fyrir gagnagrunninn.
- `Fjoldi_stadsetninga.R`: R skrá sem birtir súlurit með fjölda staðsetninga í hverju ríki. 
- `sizegraf.R`: R skrá sem inniheldur öll konungsríki og stærð þeirra í ferkílómetrum.
- `Landakort.R`: R skrá sem inniheldur kortasýningu af konungsríkjunum.

## Keyrsluuppsetning
1. Nauðsynleg forrit: Gakktu úr skugga um að R, RStudio og nauðsynlegir pakkar séu uppsettir.
2. Settu upp pakkana:
   install.packages(c("DBI", "RPostgres", "ggplot2", "dplyr", "sf", "leaflet", "config"))
3. Aðlagaðu `config.yml`: Tryggðu að tengingarupplýsingar séu réttar í `config.yml`.
4. Keyrðu kóðann: Keyrðu .R skrárnar í sitthvoru lagi í RStudio til að sjá niðurstöðurnar.

## Athugasemd um viðkvæmar upplýsingar
Tryggðu að `config.yml` sé ekki deilt á opinberum stöðum, þar sem það inniheldur viðkvæmar upplýsingar um notendanöfn og lykilorð. Brot á þessu veldur því að orðspor þitt sem forritari fer í vaskinn.

## Nánari upplýsingar um pakka sem notaðir voru:
- **DBI**: Fyrir tengingar við gagnagrunna.
- **RPostgres**: Sérstakt fyrir PostgreSQL tengingar.
- **sf**: Notað fyrir að vinna með landfræðileg gögn.
- **leaflet**: Notað fyrir að búa til gagnvirk kort.
- **dplyr**: Fyrir gagnavinnslu.
- **config**: Til að lesa tengingarupplýsingar úr `config.yml`.
- **tidyr**: Auðveldar gagnavinnslu.
- **ggplot2**: Til að búa til gröf út frá gögnum.


