import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// 1. Interface para carregar as moedas
abstract class CurrencyService {
  Future<Map<String, dynamic>> fetchCurrencyRates();
}

// 2. Implementação concreta do CurrencyService usando a API
class CurrencyServiceImpl implements CurrencyService {
  final http.Client client;

  CurrencyServiceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> fetchCurrencyRates() async {
    final response = await client
        .get(Uri.parse("https://economia.awesomeapi.com.br/json/all"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao carregar moedas');
    }
  }
}

// 3. Classe que realiza a conversão de moedas
class CurrencyConverter {
  final CurrencyService currencyService;

  CurrencyConverter({required this.currencyService});

  Future<double> convertCurrency(
      String fromCurrency, String toCurrency, double amount) async {
    try {
      final rates = await currencyService.fetchCurrencyRates();

      // Verificar se a chave 'ask' existe antes de tentar acessá-la
      if (rates.containsKey(fromCurrency) &&
          rates[fromCurrency] != null &&
          rates[fromCurrency]['ask'] != null) {
        final rate = double.parse(rates[fromCurrency]['ask']);
        return rate * amount;
      } else {
        throw Exception('Taxa de câmbio não encontrada para $fromCurrency');
      }
    } catch (e) {
      // Tratar qualquer erro que ocorrer durante a conversão
      throw Exception('Erro ao realizar a conversão: $e');
    }
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CurrencyConverterScreen(),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  bool loading = true;
  List<String> moedas = [];
  String? moedaSelecionada;
  String moedaBValor = '';
  double valorConvertido = 0;
  CurrencyService currencyService = CurrencyServiceImpl(client: http.Client());
  CurrencyConverter currencyConverter = CurrencyConverter(
      currencyService: CurrencyServiceImpl(client: http.Client()));

  @override
  void initState() {
    super.initState();
    loadMoedas();
  }

  // Carregar as moedas
  Future<void> loadMoedas() async {
    try {
      final rates = await currencyService.fetchCurrencyRates();
      setState(() {
        moedas = List<String>.from(rates.keys);
        moedaSelecionada = moedas.isNotEmpty ? moedas[0] : null;
        loading = false;
      });
    } catch (e) {
      // Lidar com erro ao carregar moedas
      print("Erro ao carregar moedas: $e");
    }
  }

  // Converter moeda
  Future<void> converter() async {
    if (moedaBValor.isEmpty || moedaSelecionada == null) return;

    try {
      final valor = await currencyConverter.convertCurrency(
          moedaSelecionada!, "BRL", double.parse(moedaBValor));
      setState(() {
        valorConvertido = valor;
      });
    } catch (e) {
      // Lidar com erro de conversão
      print("Erro ao converter moeda: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatar o valor convertido em moeda brasileira com vírgula
    String formatarMoeda(double valor) {
      final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      return formatador.format(valor);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversor de Moeda'),
        backgroundColor: Colors.green[800], // AppBar em verde escuro
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Seletor de Moeda
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 16),
                      child: DropdownButton<String>(
                        value: moedaSelecionada,
                        hint: Text("Selecione a moeda desejada para conversão"),
                        isExpanded: true,
                        items: moedas.map((moeda) {
                          return DropdownMenuItem<String>(
                            value: moeda,
                            child: Text(moeda),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            moedaSelecionada = value!;
                          });
                        },
                      ),
                    ),

                    // Entrada do valor da moeda
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Digite o valor em real para a conversão',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(
                              0xFFF2F2F2), // Fundo cinza claro para o campo de texto
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            moedaBValor = value;
                          });
                        },
                      ),
                    ),

                    // Botão de conversão
                    ElevatedButton(
                      onPressed: converter,
                      child: Text('Converter'),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFfb4b57),
                        minimumSize:
                            Size(double.infinity, 45), // Tamanho ajustado
                      ),
                    ),

                    // Resultado da conversão
                    if (valorConvertido > 0)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 24),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$moedaBValor $moedaSelecionada',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'corresponde a',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Exibe o valor convertido formatado corretamente
                            Text(
                              formatarMoeda(valorConvertido),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      backgroundColor: Color(0xDDDDDDDDD),
    );
  }
}
