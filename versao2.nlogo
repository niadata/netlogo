globals [
  min-price
  population
  starting-asking-price
  starting-willing-to-pay
  amount-high
  amount-low
  sales-per-tick
  ; these variables track data as the model runs
  avg-per-buyer
  avg-per-seller
  total-sales
  remaining-supply
  starting-money-actual
]

breed [sellers seller]
breed [buyers buyer]
breed [ shadows shadow ]
breed [ pops pop ]

turtles-own [
  money        ; keeps track of the amount of money the turtle has
  next-xcor    ; the x-coordinate of the next position
  next-ycor    ; the y-coordinate of the next position
  percent
]

sellers-own [
  items-for-sale
  asking-price
  starting-supply
  sold ; the quantity that the seller has sold
]

buyers-own [
  want-to-buy
  willing-to-pay
  starting-demand
  bought ; the quantity that the buyer has bought
]

to setup
  clear-all
  
  set min-price 0.01
  set total-sales 0
  let num-humanos 10  ; Número de tartarugas a serem criadas
  let spacing (max-pxcor * 2) / (num-humanos + 1)  ; Espaçamento entre tartarugas
  set starting-asking-price 100
  set starting-willing-to-pay 10
  set amount-high 50
  set amount-low 25
  

  create-sellers  num-humanos [
    forward 8
    setxy random-xcor (max-pycor - 1)
    set money 0
    set items-for-sale 50
    set asking-price random-float 10 + 1
    set color blue
    set shape "person"
    set starting-supply items-for-sale
    ;update-seller-display
  ]

  create-buyers  num-humanos [
    forward 13
    facexy 0 0
    setxy random-xcor (min-pycor + 5)
    set money 100
    set want-to-buy 10
    set willing-to-pay random-float 10 + 1
    set color red
    set shape "person"
    set starting-demand want-to-buy
  ]
  
  
  ; update our tracking variables
  set avg-per-buyer (sum [starting-demand] of buyers) / (count buyers)
  set avg-per-seller (sum [starting-supply] of sellers) / (count sellers)

  ;ask buyers [ update-buyer-display ]
  set starting-money-actual sum [money] of buyers

  reset-ticks
end

to-report get-random-amount [ dist amount ]
  report ifelse-value dist = "even" [
    1 + random (get-amount amount)
  ] [ ; "concentrated"
    1 + floor random-exponential ((get-amount amount) / 2)
  ]
end

to-report get-amount [ amount ]
  report ifelse-value amount = "high" [
    amount-high
  ] [ ; else "low"
    amount-low
  ]
end

to go
  if all? sellers [items-for-sale = 0] or all? buyers [money = 0 or want-to-buy = 0] [stop]
  
  clear-drawing
  set sales-per-tick 0
  
  ask buyers [
    let my-seller one-of sellers with [items-for-sale > 0 and asking-price <= money and asking-price <= willing-to-pay]
    if my-seller != nobody [
      do-commerce-with my-seller
    ]
  ]
  
  set total-sales total-sales + 1
  
  set remaining-supply (sum [items-for-sale] of sellers)

  ;let offset 1 + ticks mod population
  ;foreach (range 0 population) [ i ->
    ;let the-seller seller (population * 0 + i)
    ;let the-buyer buyer (population * 1 + ((i + offset) mod population))
    ;ask the-buyer [ do-commerce-with the-seller ]
  ;]

  ask buyers [update-buyer-display]
  ask sellers [update-seller-display]
  set total-sales (total-sales + sales-per-tick)

  ask pops [
    ifelse (size < 0.1 or not stars?)
    [ die ]
    [
      set heading (atan (random-float 0.5 - 0.25) 1)
      jump 0.5
      set size size - 0.025
      set color color - 0.25
    ]
  ]

  ; sanity check
  if (any? buyers with [want-to-buy > 0 and willing-to-pay > money]) [ error "Cannot have turtles that want to pay more than their cash!" ]

  tick
end

to update-buyer-display
  if want-to-buy = 0 [
    set color 2
  ]
  set size 1 + (bought / avg-per-buyer)
  let shadow-size 1 + (want-to-buy / avg-per-buyer)
end

to update-seller-display
  if items-for-sale = 0 [ set color 2 ]
  set size 1 + (items-for-sale / avg-per-seller)
end


to do-commerce-with [my-seller]
  let price [asking-price] of my-seller
  set want-to-buy want-to-buy - 1
  set money money - price
  
  ask my-seller [
    set items-for-sale items-for-sale - 1
    set money money + price
  ]
   ;ask buyers [ update-buyer-display ]
  set starting-money-actual sum [money] of buyers

  ;reset-ticks
end


to-report seller-cashe
  report sum [money] of sellers
end

to-report average-price
  report (ifelse-value total-sales = 0 [ 0.00 ] [ precision (seller-cash / total-sales) 2 ])
end

to-report percent-items-sold
  report 100 * sum [items-for-sale] of sellers / (population * 50)
end

to-report percent-demand-satisfied
  report 100 * sum [want-to-buy] of buyers / (population * 10)
end
to-report seller-cash
  report sum [money] of sellers
end

to-report percent-money-taken
  report 100 * sum [money] of sellers / starting-money-actual
end


to-report check-for-min-price [ value ]
  report precision ifelse-value value < min-price [min-price] [value] 2
end
