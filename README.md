# Breast Cancer Incidence Analysis

Progetto realizzato per il corso di **Metodi Statistici in Biomedicina**.

L’analisi studia la relazione tra il tasso di nuovi casi di cancro mammario e alcune variabili demografiche e territoriali, con particolare attenzione all’età e all’area geografica di appartenenza.

## Obiettivo

L’obiettivo del progetto è valutare come il tasso di incidenza del cancro mammario vari in funzione di:

* area geografica;
* classe di età;
* anno di calendario.

L’analisi è stata condotta utilizzando modelli di regressione per dati di conteggio, con aggiustamento per popolazione a rischio.

## Variabili considerate

Il dataset include le seguenti variabili principali:

* `Case`: numero di nuovi casi di cancro mammario;
* `Popu`: popolazione a rischio;
* `Area`: area geografica (`0 = area A`, `1 = area B`);
* `Aged`: classe di età;
* `Year`: anno di calendario, dal 1995 al 2006.

Sono state inoltre create alcune variabili derivate:

```r
rate <- Case / Popu * 100000
log_rate <- log(rate)
Age <- c(25, 35, 45, 55, 65)
Age2 <- Age^2
```

Il tasso è espresso come numero di nuovi casi ogni 100.000 persone a rischio.

## Analisi esplorativa

Il tasso medio complessivo di incidenza è pari a:

```r
Mean rate = 39.07
Median rate = 23.19
Standard deviation = 40.94
```

L’analisi descrittiva mostra una forte crescita del tasso di cancro mammario all’aumentare dell’età.

```r
21-30 anni  -> 1.04 casi ogni 100.000
31-40 anni  -> 6.21 casi ogni 100.000
41-50 anni  -> 23.03 casi ogni 100.000
51-60 anni  -> 54.46 casi ogni 100.000
61-70 anni  -> 110.62 casi ogni 100.000
```

Le differenze tra anni risultano invece più contenute, mentre l’area `0` presenta un tasso medio superiore rispetto all’area `1`.

```r
Area 0 -> 42.32 casi ogni 100.000
Area 1 -> 35.83 casi ogni 100.000
```

## Relazione tra area geografica e tasso di incidenza

È stato stimato un modello aggiustato per età e anno di calendario.

Il coefficiente associato all’area geografica è pari a:

```r
beta_area = 0.1686
```

L’interpretazione sul piano moltiplicativo è:

```r
exp(0.1686) = 1.184
```

A parità di età e anno, il tasso stimato nell’area `0` risulta quindi circa il **18% più elevato** rispetto all’area `1`.

```r
Deviance / df = 0.9640
```

Il valore indica un adattamento complessivamente adeguato del modello.

## Effetto dell’età

L’età rappresenta la variabile maggiormente associata al tasso di incidenza.

Per valutare una possibile relazione non lineare, è stato introdotto un termine quadratico:

```r
log(rate) ~ Area + Year + Age + Age2
```

Entrambi i coefficienti risultano statisticamente significativi:

```r
Age  -> 0.2370
Age2 -> -0.0014
```

La significatività di `Age2` evidenzia una relazione quadratica tra età e logaritmo del tasso di incidenza.

```r
Deviance / df = 1.0869
```

Anche questo valore suggerisce un buon adattamento del modello ai dati.

## Principali risultati

L’analisi evidenzia che:

* il tasso di nuovi casi di cancro mammario aumenta fortemente con l’età;
* l’area geografica `0` presenta tassi stimati superiori di circa il 18% rispetto all’area `1`;
* l’andamento dell’età non è puramente lineare, ma presenta una componente quadratica significativa;
* le variazioni annuali risultano meno rilevanti rispetto a quelle associate a età e area geografica;
* i modelli utilizzati mostrano una devianza rapportata ai gradi di libertà vicina a 1, indicando una buona qualità dell’adattamento.

## Conclusioni

Il progetto mostra come l’utilizzo di modelli di regressione per dati epidemiologici permetta di distinguere l’effetto delle principali variabili associate al rischio di malattia.

In questo caso, l’età emerge come il principale fattore associato al tasso di incidenza del cancro mammario, mentre la differenza tra le due aree geografiche rimane significativa anche dopo l’aggiustamento per età e anno di calendario.

