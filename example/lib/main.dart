import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:var_widget/var_widget.dart';
import 'package:var_widget_example/util.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Var<int>> vars;
  Var<int> idx;

  @override
  void initState() {
    super.initState();

    vars = List.generate(15, (i) => new Var(0, debugLabel: 'Var $i'));
    idx = new Var(0, debugLabel: 'index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('var_widget'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 10),
            height: 150,
            child: ListView.builder(
              itemCount: vars.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int i) {
                final Color randColor = RandomColor().randomColor();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: 100,
                  color: randColor,
                  child: GestureDetector(
                    child: Card(
                      color: randColor,
                      child: Center(
                        child: VarBuilder<int>(
                          value: vars[i],
                          builder: (BuildContext context, int v, Widget child) => Text('$v'),
                        ),
                      ),
                    ),
                    onTap: () => idx.value = i,
                  ),
                );
              },
            ),
          ),
          Divider(),
          Center(
            child: VarBuilder<int>(
              value: idx,
              builder: (BuildContext context, int idx, Widget child) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: InkWell(
                    child: Card(
                      child: Center(
                        child: VarBuilder<int>(
                          value: vars[idx],
                          builder: (BuildContext context, int v, Widget child) {
                            return Text(
                              '$v',
                              style: Theme.of(context).textTheme.display1,
                            );
                          },
                        ),
                      ),
                      color: Colors.blueAccent,
                    ),
                    onTap: () => vars[idx].value++,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
