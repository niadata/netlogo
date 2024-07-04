globals [
  market-price      ; Preço de mercado atual
  items-remaining   ; Quantidade de itens
  price             ; preço atual
  prices            ; lista de preços ao longo do tempo
  alpha             ; parâmetro de ajuste de preços
  price-history
  buy-orders
  sell-orders
  preco-ativo       ; preço atual do ativo
  preco-anterior    ; preço anterior do ativo
  retorno       ; lista de retornos
  order-balance ; balanco de ordens
]
turtles-own [
  buyer?            ; indicador se é comprador
  seller?           ; indicador se é vendedor
  budget            ; saldo em dinheiro do agente
  dividend          ; d0
  growth            ; g
  return            ; r
  estimated-price   ; preço calculado pela formula - CALCULA A CADA 15 TICKS - "if ticks mod 15 = 0"
  agent-type   ; tipo do agente (A ou B)
  order
]
to setup
  clear-all
  set market-price 100
  set price-history []
  set price 100
  set prices (list price)
  set items-remaining 1000 ; Definir o número inicial de itens para serem vendidos
   set preco-ativo preco-inicial
   set preco-anterior preco-inicial
   set buy-orders 0
   set sell-orders 0
  
  ; Criar agentes Tipo A (informados pelos dividendos)
  create-turtles 100 [
    set agent-type "A"
    set shape "person"
    set color blue
  ]
  ; Criar agentes Tipo B (inteligência zero)
  create-turtles 100 [
    set agent-type "B"
  set shape "person"
  set color blue
  ]
  position-turtles-in-circle
  reset-ticks
  setup-plot
end
to position-turtles-in-circle
  let radius 15
  let angle 0
  let angle-step 360 / count turtles
  ask turtles [
    setxy (radius * cos angle) (radius * sin angle)
    set angle angle + angle-step
  ]
end
to initialize-agent

    set dividend (0.1 * market-price + random-normal 0 0.5)  ; D0: entre 1 e 6
    set growth (random-float 0.025 + 0.04)                   ; g: entre 4.0% e 6.5%
    set return (random-float 0.1 + 0.1)                      ; r: entre 10% e 20%
    set budget (random 100 + 50)                             ; Orçamento inicial entre 50 e 150

  set market-price 1000
end
to calculate-estimated-price
   if ticks mod 15 = 0 [  ; calcula a fórmula de Gordon a cada 15 ticks
      set estimated-price (dividend * (1 + growth)) / (return - growth)
  ]
end
to go
  decide-action-A
  decide-action-B
 ;execute-action
  update-market-price
  tick
end

to decide-action-A
   ask turtles [
    if agent-type = "A" [  ; Agente A decide baseado no mercado
    let decision random 3
    initialize-agent
    calculate-estimated-price
    if decision = 0 [ ; Agente A decide comprar
        set buyer? true
        set seller? false
        set budget (random 100 + 50)          ; Orçamento inicial entre 50 e 150
      if market-price < estimated-price [
        set color pink
        set budget budget - market-price
        set items-remaining items-remaining - 1
        set market-price market-price + random-float 1 * one-of [-1 1]
      ]
    ]
    if decision = 1 [ ; Agente A decide vender
      set seller? true
      if estimated-price < market-price [ ; Vender ação
        set color yellow
        set items-remaining items-remaining + 1
        set market-price market-price - random-float 1 * one-of [-1 1]
      ]
    ] ; Se decision = 2, o agente não faz nada tera uma cor aleatorio
  ]
  ]
end

to decide-action-B
 ask turtles [
 if agent-type = "B" [ ; Agente B decide aleatoriamente
    let decision random 2
    if decision = 0 [ ; Agente B decide comprar
      set budget (random 100 + 50)          ; Orçamento inicial entre 50 e 150
      set buyer? true
      set seller? false
      set color gray
    ]
    if decision = 1 [ ; Agente B decide vender
      set buyer? false
      set seller? true
      set color violet
    ]
  ]]
end

to execute-action
  set items-remaining sum [items-remaining] of agent-type with [seller? = True] ; calcular o total de compras
  set buy-orders sum [items-remaining] of agent-type with [buyer? = True] ; calcular o total de vendas
  set alpha buy-orders - sell-orders ; calcular o spread
  set preco-anterior preco-ativo
  set preco-ativo preco-anterior * exp(order-balance * coeficiente-ajuste-ordem)
end

to update-market-price
  set price-history lput market-price price-history
  ; Limitar o histórico a 100 ticks
  if length price-history > 100 [
    set price-history but-first price-history
  ]
  update-plot
end

to setup-plot
  set-current-plot "Market Price"
  set-plot-x-range 0 100
  set-plot-y-range 0 200
  clear-all-plots
end

to update-plot
  set-current-plot "Market Price"
  plot market-price
end
