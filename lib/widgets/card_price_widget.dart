import 'package:flutter/material.dart';
import '../models/card_price.dart';
import '../services/price_service.dart';

class CardPriceWidget extends StatefulWidget {
  final String cardId;
  final double fontSize;
  final bool showRange;

  const CardPriceWidget({
    super.key,
    required this.cardId,
    this.fontSize = 10,
    this.showRange = false,
  });

  @override
  State<CardPriceWidget> createState() => _CardPriceWidgetState();
}

class _CardPriceWidgetState extends State<CardPriceWidget> {
  final PriceService _priceService = PriceService();
  CardPrice? _price;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final price = await _priceService.getCardPrice(widget.cardId);
      if (mounted) {
        setState(() {
          _price = price;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.fontSize + 4,
        child: Center(
          child: SizedBox(
            width: widget.fontSize,
            height: widget.fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      );
    }

    if (_price == null || !_price!.isAvailable) {
      return Text(
        'Prix N/A',
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prix moyen
        Text(
          _price!.formattedAvgPrice,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
          textAlign: TextAlign.center,
        ),
        
        // Fourchette de prix (optionnel)
        if (widget.showRange && _price!.formattedPriceRange.isNotEmpty)
          Text(
            _price!.formattedPriceRange,
            style: TextStyle(
              fontSize: widget.fontSize - 1,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class CollectionValueWidget extends StatefulWidget {
  final Map<String, int> collection;
  final double fontSize;

  const CollectionValueWidget({
    super.key,
    required this.collection,
    this.fontSize = 16,
  });

  @override
  State<CollectionValueWidget> createState() => _CollectionValueWidgetState();
}

class _CollectionValueWidgetState extends State<CollectionValueWidget> {
  final PriceService _priceService = PriceService();
  double? _totalValue;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateValue();
  }

  @override
  void didUpdateWidget(CollectionValueWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection != widget.collection) {
      _calculateValue();
    }
  }

  Future<void> _calculateValue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final value = await _priceService.calculateCollectionValue(widget.collection);
      if (mounted) {
        setState(() {
          _totalValue = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.fontSize,
            height: widget.fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Calcul en cours...',
            style: TextStyle(fontSize: widget.fontSize),
          ),
        ],
      );
    }

    if (_totalValue == null) {
      return Text(
        'Valeur non calculable',
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Colors.black87,
        ),
        children: [
          const TextSpan(text: 'Valeur estimée: '),
          TextSpan(
            text: '${_totalValue!.toStringAsFixed(2)} EUR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
