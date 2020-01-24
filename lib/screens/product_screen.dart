import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/product.dart';
import 'package:shop_app/providers/products_provider.dart';

class ProductScreen extends StatefulWidget {
  static const routeName = '/product';

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descFocusNode = FocusNode();
  final _imageUrlFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _product = Product(
    id: null,
    title: '',
    price: 0,
    description: '',
    imageUrl: '',
  );
  var _initValues = {
    'title': '',
    'price': '',
    'description': '',
    'imageUrl': '',
  };
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context).settings.arguments as String;
      if (productId != null) {
        _product = Provider.of<Products>(context).findById(productId);
        _initValues = {
          'title': _product.title,
          'price': _product.price.toString(),
          'description': _product.description,
          'imageUrl': '',
        };
        _imageUrlController.text = _product.imageUrl;
      }
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      setState(() {});
    }
  }

  void _saveForm() {
    final _isValid = _form.currentState.validate();
    if (!_isValid) {
      return;
    }
    _form.currentState.save();
    setState(() {
      _isLoading = true;
    });
    if (_product.id != null) {
      Provider.of<Products>(context, listen: false)
          .updateProduct(_product.id, _product);
      Navigator.of(context).pop();
      _isLoading = false;
    } else {
      Provider.of<Products>(context, listen: false)
          .addProduct(_product)
          .catchError(
        (error) {
          return showDialog<Null>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('An error occurred'),
              content: Text('Something went wrong'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: (){
                    Navigator.of(ctx).pop();
                  },
                )
              ],
            ),
          );
        },
      ).then(
        (_) {
          Navigator.of(context).pop();
          _isLoading = false;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Title'),
                      initialValue: _initValues['title'],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (val) {
                        return val.isEmpty ? 'Please provide a value' : null;
                      },
                      onSaved: (val) {
                        _product = Product(
                          id: _product.id,
                          isFavorite: _product.isFavorite,
                          title: val,
                          price: _product.price,
                          description: _product.description,
                          imageUrl: _product.imageUrl,
                        );
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Price'),
                      initialValue: _initValues['price'],
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_descFocusNode);
                      },
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(val) <= 0) {
                          return 'Please enter a number greater than zero';
                        }
                        return null;
                      },
                      onSaved: (val) {
                        _product = Product(
                          id: _product.id,
                          isFavorite: _product.isFavorite,
                          title: _product.title,
                          price: double.parse(val),
                          description: _product.description,
                          imageUrl: _product.imageUrl,
                        );
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Description'),
                      initialValue: _initValues['description'],
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descFocusNode,
                      validator: (val) =>
                          val.isEmpty ? 'Please enter a description' : null,
                      onSaved: (val) {
                        _product = Product(
                          id: _product.id,
                          isFavorite: _product.isFavorite,
                          title: _product.title,
                          price: _product.price,
                          description: val,
                          imageUrl: _product.imageUrl,
                        );
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(top: 8, right: 10),
                          decoration: BoxDecoration(
                              border: Border.all(width: 1, color: Colors.grey)),
                          child: _imageUrlController.text.isEmpty
                              ? Text('Enter a URL')
                              : FittedBox(
                                  child: Image.network(
                                    _imageUrlController.text,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Image URL'),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            controller: _imageUrlController,
                            focusNode: _imageUrlFocusNode,
                            validator: (val) => val.isEmpty
                                ? 'Please enter an image URL'
                                : null,
                            onFieldSubmitted: (_) {
                              _saveForm();
                            },
                            onSaved: (val) {
                              _product = Product(
                                id: _product.id,
                                isFavorite: _product.isFavorite,
                                title: _product.title,
                                price: _product.price,
                                description: _product.description,
                                imageUrl: val,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
