rpg_game
========

RPGをつくろうとした。

##ui-accessor

RubyとWebViewの橋渡しをする`ui-accessor`作った。

Rubyで処理、HTML5で描画を行う。描画の操作もすべてRubyから行える。だいたい必要なメソッドはjQueryのメソッドをそのままRubyで使える。(引数にfunctionを取るメソッドは使えない)

bindを利用してイベントの設定を行い、Rubyのメソッドを呼ぶことができる。

####利点

* RubyからjQueryライクにUIを動的に操作できる。

####欠点

* Websocketで橋渡しをしているので、Ruby-HTML5間の通信が多くなれば多くなるほど遅くなる

描画処理をまとめてjsにfunctionとして定義しておいて、Rubyからそのfunctionを呼んであげれば、1回まとまったデータを送れば描画操作はjs側で行えるため高速化され、欠点はある程度緩和される。(Lumillyのような)

ただ、jsの役割はRubyとの橋渡しのみで、Rubyを完全に分離し、すべての操作をRubyから行いたかったので本来の目的からだいぶ外れてしまう。

RPGは適当に作った。マップの描画のみ。予想外にかなり遅い。

jsの方は未完成。

###ui-accessorのサンプル

```
app = UIAccessor::App.new

app.script do
  # websocketが開いたときに呼ばれる
  function("open") {
    puts "opened"
  }

  # websocketが相互接続された時に呼ばれる
  function("load") {
  	# $(".test")を行う
    elm = jquery(".test")

    # jQueryと同じ.css()
    # 引数はjsでObjectならHash、それ以外は同じもの。整数は上限注意。
    elm.css({
      "height" => "100px",
      "background-color" => "#FF0000"
    })

	# jQueryと同じ.append()
    elm.append("<span class='test_span'>Hello</span>")

    elm2 = jquery(".test_span")

	# jQueryオブジェクトを引数にしたい場合はそのまま使える
	elm.wrap(elm2)

	# $(".test")にidを追加する
    elm.attr("id", "test")
    
    # idが指定されている場合bindでイベントを設定できる
    # onclickなどは引数にfunction objectを取るため使えない
    elm.bind("click")
  }

  # idがtestのclickイベントはfunction("click", "test")にコールバックされる
  # eにはeventObjectが入ってる(jQueryのもの)
  function("click", "test") { |e|
    puts "clicked"
  }
  
  # websocketが閉じたときに呼ばれる
  function("close") {
  	puts "closed"
  }
end

app.start
```