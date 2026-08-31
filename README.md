<div align="center">

# ☠️ wkdead
<sub>dados de uma série onde “última aparição” é mais uma sugestão do que um fato</sub>

<br>
<img src="https://img.shields.io/badge/fandom-fa005a?style=for-the-badge&logo=fandom&logoColor=white">
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white">
<img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white">

<a href="https://docs.flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white"></a>
<a href="https://fastapi.tiangolo.com/"><img src="https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white"></a>
<a href="https://www.typescriptlang.org/docs/"><img src="https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white"></a>
<a href="https://playwright.dev/docs/intro"><img src="https://img.shields.io/badge/Playwright-2EAD33?style=flat-square&logo=playwright&logoColor=white"></a>
<a href="https://redis.io/docs/latest/"><img src="https://img.shields.io/badge/Redis-DC382D?style=flat-square&logo=redis&logoColor=white"></a>
</div>

## Visão geral

The Walking Dead tem uma característica particularmente inconveniente: os personagens não sabem quando terminar uma participação.

Você encontra um personagem em um episódio, acompanha o sujeito durante uma temporada inteira, vê a vida dele virar uma merda, chega à conclusão de que ele finalmente morreu e segue sua vida. Aí, algum tempo depois, ele aparece novamente. Às vezes vivo. Às vezes morto. Às vezes como zumbi. Às vezes em uma lembrança. E às vezes a única explicação disponível é aquela velha tradição televisiva de simplesmente seguir em frente como se nada tivesse acontecido.

Foi nessa parte que eu comecei a querer saber onde cada personagem realmente estava ao longo da série.

O [Fandom](https://walkingdead.fandom.com/wiki/The_Walking_Dead_Wiki) já tem as informações. O problema é que elas estão espalhadas por páginas de temporadas, episódios e, principalmente, pelas Trivia de cada episódio, onde aparecem registros como primeira aparição e última aparição.

Então este projeto pega essas informações, organiza tudo no PostgreSQL e apresenta a série por outro ângulo: não pelo episódio que você está assistindo, mas pela trajetória de quem está dentro dele.

E, sinceramente, depois de colocar isso em um banco de dados, fica difícil olhar para a série da mesma maneira.

### 👁️ A ideia

Imagine abrir a página de um personagem e conseguir enxergar sua história inteira de
uma vez: a primeira temporada em que apareceu, os episódios em que entrou, o momento
em que deixou de aparecer, uma eventual volta, a última aparição enquanto estava vivo. 
E, se o universo decidiu que a morte daquela pessoa precisava de uma segunda opinião,
a aparição posterior como zumbi.

Isso é bem interessante em The Walking Dead porque morrer não necessariamente encerra
uma linha do tempo. Glenn morreu. Shane morreu. Hershel morreu. Mas a série tem uma relação
tão criativa com o conceito de morte que, se você der cinco minutos, provavelmente encontra
uma maneira de colocar qualquer um deles de volta na tela.

O projeto não tenta decidir se isso é bom ou ruim. Ele só registra.

Afinal, eu não vou discutir com o universo que inventou uma epidemia de zumbis e depois
achou razoável colocar o cavalo de Rick em uma situação mais tensa do que muita gente.

### 🏆 Troféus

A trajetória dos personagens também vira uma pequena coleção de troféus.

Apareceu em todas as temporadas? Tem um troféu. Apareceu em um único episódio? Também tem.
Teve uma trajetória particularmente longa? Pode ganhar alguma coisa por isso.

E eu sei o que você está pensando: “por que alguém ganharia um troféu por aparecer em um único episódio?”
Porque essa é justamente a graça. Imagine ser um personagem de The Walking Dead, entrar na série,
sobreviver ao caos, aos zumbis, aos grupos de sobreviventes, às decisões do Rick, à falta de comida,
ao Governador, aos Salvadores e a tudo mais que essa gente inventou para tornar a vida insuportável...
e depois simplesmente nunca mais aparecer.

Um episódio. Fim. Parabéns pela participação.

Há algo quase elegante nisso.

### 📊 A parte em que alguém estraga uma boa série transformando tudo em número

Também dá para olhar os personagens por métricas. Quantos episódios tiveram sua participação registrada,
em quantas temporadas apareceram, quais foram suas formas de aparição, quantos episódios atravessaram
e qual foi sua porcentagem de presença sobre o total.

Isso permite comparar personagens de uma maneira que a série jamais pediu. Rick Grimes pode ser analisado
como protagonista. Ou pode ser analisado como “qual foi a porcentagem dos episódios em que esse homem
esteve presente enquanto sua vida lentamente se transformava em um problema de saúde pública?”

As duas abordagens são válidas; eu prefiro a segunda.

### 📺 E se a pergunta for sobre um episódio?

A navegação também pode ser feita pela temporada: escolha a temporada, escolha o episódio e veja quais
personagens tiveram sua primeira aparição ali e quais tiveram sua última aparição.
É uma visão especialmente boa para perceber como o elenco vai mudando conforme a série avança.

Algumas pessoas entram, algumas pessoas saem. Algumas pessoas entram, saem e depois voltam porque
aparentemente ninguém conversou direito sobre o significado de "última".

E, no meio disso, Carol continua existindo. O que, olhando em retrospecto, talvez seja a coisa mais
sensata que alguém fez naquela série.

### ☠️ No fim, é sobre enxergar a série de outro jeito

Este projeto nasceu de uma curiosidade bastante específica e acabou virando uma maneira diferente
de navegar por The Walking Dead. Não é uma tentativa de substituir o Fandom, muito menos de reconstruir
cada aparição de cada personagem em cada segundo da série. O foco está nos momentos que marcam a
trajetória deles: quando entram, quando saem e quando a série resolve que “saiu” não era exatamente o
que queria dizer.

A fonte também possui inconsistências, e elas não são escondidas. Se existe uma primeira aparição sem
uma última aparição correspondente, o registro continua existindo e a interface sinaliza o problema.

Porque, no final, este projeto não precisa fingir que The Walking Dead é organizado: só precisa ser
organizado o bastante para mostrar a bagunça.


## Funcionalidades

O projeto existe para responder uma pergunta que ninguém fez, mas que, uma vez feita,
torna-se impossível desver: afinal, onde diabos os personagens de The Walking Dead
estavam durante tudo isso?

A aplicação pega dados do Fandom de The Walking Dead, atravessa temporadas, episódios e
aquelas seções de Trivia que parecem ter sido escritas por alguém que sabia exatamente
onde colocar uma informação importante e decidiu colocá-la no lugar menos conveniente
possível, e transforma tudo isso em uma visão mais organizada dos acontecimentos.

### Visão por personagens

<img width="3840" height="2160" alt="1" src="https://github.com/user-attachments/assets/3f42cc21-5c00-4d62-8c1f-397ac3b42065" />

Escolhendo um personagem, a aplicação mostra sua trajetória ao longo da série a partir
das aparições identificadas no processo de _scraping_, incluindo:

- quando o personagem entra e sai da história ao longo das temporadas:

  <img width="3840" height="2160" alt="2" src="https://github.com/user-attachments/assets/0075f27a-8c8f-46a4-b084-f58d1b672e66" />

- pequenas conquistas baseadas em sua trajetória, como aparecer em todas as temporadas
  ou ter participado de apenas um episódio; é uma gamificação de estatísticas que
  provavelmente não precisava existir, o que talvez seja exatamente o motivo de existir:

  <img width="3840" height="2160" alt="3" src="https://github.com/user-attachments/assets/4c7a97bf-7bef-4fe4-bfdf-37f438600e15" />

- informações sobre suas formas de aparição, quantidade de episódios em que sobreviveu
  e sua participação percentual no total de episódios:

  <img width="3840" height="2160" alt="4" src="https://github.com/user-attachments/assets/1ceaf782-afeb-458c-a8d8-367fef305c22" />

A ideia é transformar uma sequência de registros em uma espécie de histórico de carreira.
Só que, em vez de promoções, mudanças de emprego e uma foto profissional em fundo azul,
temos alguém desaparecendo de uma temporada e reaparecendo posteriormente como zumbi.
Cada um administra o LinkedIn que tem.

### Visão por temporadas

Também é possível navegar pela série a partir das temporadas e episódios:

<img width="3840" height="2160" alt="T1" src="https://github.com/user-attachments/assets/2753a080-15b5-4a43-9e92-57c2eb31c3ad" />

Ao selecionar um episódio, a aplicação apresenta as altas (personagens cuja primeira aparição
ocorre naquele episódio) e baixas (personagens cuja última aparição ocorre naquele episódio)
daquele ponto da história:

<img width="3840" height="2160" alt="T2" src="https://github.com/user-attachments/assets/c578d674-a70d-4168-95c6-2d421549332d" />

Isso permite observar a movimentação do elenco episódio a episódio sem precisar reconstruir
mentalmente seis temporadas enquanto encara uma tabela do Fandom.

### Dados derivados do scraping

O sistema não tenta reproduzir integralmente todas as aparições de todos os personagens.
Ele coleta os _highlights_ relevantes encontrados nas páginas dos episódios, especialmente
informações de primeira e última aparição e suas respectivas formas de aparição.

Há, inclusive, um pequeno detalhe que representa bem a relação entre software e realidade:
a fonte possui inconsistências. Um personagem pode ter uma primeira aparição registrada sem
uma última aparição correspondente, por exemplo. O sistema mantém esse registro e sinaliza a
inconsistência na interface em vez de fingir que o universo é mais organizado do que realmente é.

No fim, a aplicação faz algo relativamente simples: pega uma quantidade considerável de
informação espalhada, coloca ordem nela e deixa o usuário perguntar coisas sobre a série que 
provavelmente poderiam ter sido resolvidas assistindo aos episódios. Mas aí já seria tarde
demais, porque o PostgreSQL está pronto.

## Arquitetura

A arquitetura é relativamente simples porque, em algum momento, alguém precisa tomar uma
decisão sensata.

O sistema é dividido entre a aplicação principal, responsável por apresentar e consultar
os dados, e um _pipeline_ de _bootstrap_, responsável por buscá-los no Fandom e colocá-los
no banco. O segundo existe para alimentar o primeiro e, depois disso, pode ir embora
discretamente, como aquele funcionário que participou da reunião das 9h e às 9h17 já não
lembra por que foi convidado.

### Aplicação principal

Composta por quatro serviços:

- Nginx: atua como _proxy_ reverso e ponto de entrada da aplicação, encaminhando as
  requisições para _frontend_ e _backend_.
- _Frontend_: aplicação em Dart + Flutter responsável pela interface e visualização
  dos dados.
- _Backend_: API em Python + FastAPI, responsável pelas regras de consulta e exposição
  dos dados para o _frontend_.
- PostgreSQL: banco de dados principal e fonte persistente dos dados da aplicação.

O _backend_ é responsável também pelo gerenciamento da estrutura do banco através do 
[Alembic](https://alembic.sqlalchemy.org/en/latest/). Ao subir uma instalação nova, ele
pode criar ou aplicar as migrations e deixar o PostgreSQL com a estrutura necessária
para receber os dados.

Isso significa que é perfeitamente possível subir apenas a aplicação e chegar a uma
situação tecnicamente correta, porém dramaticamente vazia: _frontend_ funcionando, API
funcionando, banco funcionando e absolutamente nada para mostrar. É o equivalente
arquitetural de abrir um restaurante, acender as luzes e descobrir que esqueceram de
comprar comida.

### Bootstrap

A carga inicial dos dados possui uma arquitetura própria, composta por:

- _Scraper_: serviço em TypeScript responsável por acessar o Fandom através do
  [Playwright](https://playwright.dev/), coletar temporadas, episódios e informações
  de aparição e persistir os resultados.
- Redis: armazenamento temporário dos resultados do _scraping_. Serve como uma espécie
  de memória intermediária para evitar que uma execução interrompida obrigue o _scraper_
  a atravessar novamente todo o Fandom.
- PostgreSQL: destino final dos dados coletados, o mesmo serviço de antes.

O _bootstrap_ depende do Redis, PostgreSQL e _backend_, enquanto a aplicação normal não
depende do scraper nem do Redis. Depois que a carga foi concluída, ambos podem ser descartados
sem afetar o funcionamento da aplicação.

Essa separação também evita misturar duas preocupações diferentes: obter os dados e servir os
dados. Uma coisa é conversar com páginas do Fandom usando Playwright; outra é responder uma
requisição HTTP sem precisar lembrar se o Rick apareceu no episódio 37 ou se aquilo era um
flashback de alguém que já estava morto havia vinte minutos.
