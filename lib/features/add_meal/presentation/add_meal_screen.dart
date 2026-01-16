import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/image_note_dialog.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late AddMealType _mealType;
  late DateTime _day;

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;
  late RecentMealBloc _recentMealBloc;

  late TabController _tabController;

  @override
  void initState() {
    _productsBloc = locator<ProductsBloc>();
    _foodBloc = locator<FoodBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Update search results when tab changes
      _onSearchSubmit(_searchStringListener.value);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as AddMealScreenArguments;
    _mealType = args.mealType;
    _day = args.day;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_mealType.getTypeName(context)),
          actions: [
            BlocBuilder<AddMealBloc, AddMealState>(
              bloc: locator<AddMealBloc>()..add(InitializeAddMealEvent()),
              builder: (BuildContext context, AddMealState state) {
                if (state is AddMealLoadedState) {
                  return IconButton(
                    onPressed: () =>
                        _onCustomAddButtonPressed(state.usesImperialUnits),
                    icon: const Icon(Icons.add_circle_outline),
                  );
                }
                return const SizedBox();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              MealSearchBar(
                searchStringListener: _searchStringListener,
                onSearchSubmit: _onSearchSubmit,
                onBarcodePressed: _onBarcodeIconPressed,
                onCameraPressed: _onCameraIconPressed,
              ),
              const SizedBox(height: 16.0),
              TabBar(
                  tabs: [
                    Tab(text: S.of(context).searchProductsPage),
                    Tab(text: S.of(context).searchFoodPage),
                    Tab(text: S.of(context).recentlyAddedLabel)
                  ],
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<ProductsBloc, ProductsState>(
                        bloc: _productsBloc,
                        builder: (context, state) {
                          if (state is ProductsInitial) {
                            return const DefaultsResultsWidget();
                          } else if (state is ProductsLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is ProductsLoadedState) {
                            return state.products.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.products.length,
                                        itemBuilder: (context, index) {
                                          return MealItemCard(
                                            day: _day,
                                            mealEntity: state.products[index],
                                            addMealType: _mealType,
                                            usesImperialUnits:
                                                state.usesImperialUnits,
                                          );
                                        }))
                                : const NoResultsWidget();
                          } else if (state is ProductsFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorFetchingProductData,
                              onRefreshPressed: _onProductsRefreshButtonPressed,
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<FoodBloc, FoodState>(
                        bloc: _foodBloc,
                        builder: (context, state) {
                          if (state is FoodInitial) {
                            return const DefaultsResultsWidget();
                          } else if (state is FoodLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is FoodLoadedState) {
                            return state.food.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.food.length,
                                        itemBuilder: (context, index) {
                                          return MealItemCard(
                                            day: _day,
                                            mealEntity: state.food[index],
                                            addMealType: _mealType,
                                            usesImperialUnits:
                                                state.usesImperialUnits,
                                          );
                                        }))
                                : const NoResultsWidget();
                          } else if (state is FoodFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorFetchingProductData,
                              onRefreshPressed: _onFoodRefreshButtonPressed,
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                  Column(
                    children: [
                      BlocBuilder<RecentMealBloc, RecentMealState>(
                          bloc: _recentMealBloc,
                          builder: (context, state) {
                            if (state is RecentMealInitial) {
                              _recentMealBloc.add(
                                  const LoadRecentMealEvent(searchString: ""));
                              return const SizedBox();
                            } else if (state is RecentMealLoadingState) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 32),
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is RecentMealLoadedState) {
                              return state.recentMeals.isNotEmpty
                                  ? Flexible(
                                      child: ListView.builder(
                                          itemCount: state.recentMeals.length,
                                          itemBuilder: (context, index) {
                                            return MealItemCard(
                                              day: _day,
                                              mealEntity:
                                                  state.recentMeals[index],
                                              addMealType: _mealType,
                                              usesImperialUnits:
                                                  state.usesImperialUnits,
                                            );
                                          }))
                                  : const NoResultsWidget();
                            } else if (state is RecentMealFailedState) {
                              return ErrorDialog(
                                errorText:
                                    S.of(context).noMealsRecentlyAddedLabel,
                                onRefreshPressed:
                                    _onRecentMealsRefreshButtonPressed,
                              );
                            }
                            return const SizedBox();
                          })
                    ],
                  )
                ]),
              )
            ],
          ),
        ));
  }

  void _onProductsRefreshButtonPressed() {
    _productsBloc.add(const RefreshProductsEvent());
  }

  void _onFoodRefreshButtonPressed() {
    _foodBloc.add(const RefreshFoodEvent());
  }

  void _onRecentMealsRefreshButtonPressed() {
    _recentMealBloc.add(const LoadRecentMealEvent(searchString: ""));
  }

  void _onSearchSubmit(String inputText) {
    switch (_tabController.index) {
      case 0:
        _productsBloc.add(LoadProductsEvent(searchString: inputText));
      case 1:
        _foodBloc.add(LoadFoodEvent(searchString: inputText));
      case 2:
        _recentMealBloc.add(LoadRecentMealEvent(searchString: inputText));
    }
  }

  void _onBarcodeIconPressed() {
    Navigator.of(context).pushNamed(NavigationOptions.scannerRoute,
        arguments: ScannerScreenArguments(_day, _mealType.getIntakeType()));
  }

  void _onCustomAddButtonPressed(bool usesImperialUnits) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).createCustomDialogTitle),
            content: Text(S.of(context).createCustomDialogContent),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(), // close dialog
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _openEditMealScreen(usesImperialUnits);
                  },
                  child: Text(S.of(context).buttonYesLabel)),
            ],
          );
        });
  }

  Future<void> _onCameraIconPressed() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      if (!mounted) return;

      // Ask for optional note
      await showDialog(
        context: context,
        builder: (context) => ImageNoteDialog(
          imageFile: photo,
          onAnalyze: (note) async {
            Navigator.of(context).pop(); // Close dialog
            await _analyzeImage(photo, note);
          },
        ),
      );
    }
  }

  Future<void> _analyzeImage(XFile photo, String? note) async {
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final apiKey = Env.geminiApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Gemini API Key is missing in .env');
      }

      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
        tools: [
          Tool(functionDeclarations: [
            FunctionDeclaration(
              'extract_nutrition_info',
              'Extracts nutritional information per 100g/ml from an image of food.',
              Schema(
                SchemaType.object,
                properties: {
                  'name': Schema(SchemaType.string,
                      description: 'The name of the food or meal.'),
                  'brands': Schema(SchemaType.string,
                      description: 'The brand name if visible/applicable.',
                      nullable: true),
                  'calories': Schema(SchemaType.number,
                      description: 'Energy content in kcal per 100g/ml.'),
                  'carbs': Schema(SchemaType.number,
                      description: 'Carbohydrates in grams per 100g/ml.'),
                  'fat': Schema(SchemaType.number,
                      description: 'Total fat in grams per 100g/ml.'),
                  'protein': Schema(SchemaType.number,
                      description: 'Protein in grams per 100g/ml.'),
                  'sugar': Schema(SchemaType.number,
                      description: 'Total sugars in grams per 100g/ml.'),
                  'fiber': Schema(SchemaType.number,
                      description: 'Dietary fiber in grams per 100g/ml.'),
                  'saturated_fat': Schema(SchemaType.number,
                      description: 'Saturated fat in grams per 100g/ml.'),
                  'serving_size': Schema(SchemaType.string,
                      description:
                          'The estimated serving size in g/ml (e.g., 250g).'),
                },
                requiredProperties: [
                  'name',
                  'calories',
                  'carbs',
                  'fat',
                  'protein',
                  'sugar',
                  'fiber',
                  'saturated_fat',
                  'serving_size'
                ],
              ),
            ),
          ]),
        ],
      );

      final imageBytes = await photo.readAsBytes();
      String promptText =
          'Identify this food and its nutritional values per 100g. Call the extract_nutrition_info function.';
      if (note != null && note.isNotEmpty) {
        promptText += ' User note: "$note".';
      }

      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);

      final functionCall = response.functionCalls.firstOrNull;

      if (functionCall != null &&
          functionCall.name == 'extract_nutrition_info') {
        final args = functionCall.args;
        final name = args['name'] as String;
        final brands = args['brands'] as String?;
        final calories = (args['calories'] as num).toDouble();
        final carbs = (args['carbs'] as num).toDouble();
        final fat = (args['fat'] as num).toDouble();
        final protein = (args['protein'] as num).toDouble();
        final sugar = (args['sugar'] as num).toDouble();
        final fiber = (args['fiber'] as num).toDouble();
        final saturatedFat = (args['saturated_fat'] as num).toDouble();
        final servingSizeString = args['serving_size'] as String;

        // Propagate serving size
        final parsedServing = _parseServingSize(servingSizeString);
        final double mealQuantityVal = parsedServing.value;
        final String mealUnitVal = parsedServing.unit;

        // Create MealEntity
        final mealEntity = MealEntity(
          code: IdGenerator.getUniqueID(),
          name: name,
          brands: brands,
          thumbnailImageUrl: photo.path, // Use local path
          mainImageUrl: photo.path,
          url: null,
          mealQuantity:
              mealQuantityVal.toString(), // Propagated from serving size
          mealUnit: mealUnitVal,
          servingQuantity: mealQuantityVal,
          servingUnit: mealUnitVal,
          servingSize: "", // Explicitly empty to avoid duplicate serving option
          nutriments: MealNutrimentsEntity(
            energyKcal100: calories,
            carbohydrates100: carbs,
            fat100: fat,
            proteins100: protein,
            sugars100: sugar,
            saturatedFat100: saturatedFat,
            fiber100: fiber,
          ),
          source: MealSourceEntity.custom,
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        Navigator.of(context).pushNamed(
          NavigationOptions.editMealRoute,
          arguments: EditMealScreenArguments(
            _day,
            mealEntity,
            _mealType.getIntakeType(),
            false, // Assuming metric for now, or match user pref
          ),
        );
      } else {
        throw Exception('Failed to extract nutrition info (No function call)');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  ({double value, String unit}) _parseServingSize(String servingSize) {
    // Basic parsing logic.
    // Expected formats: "200g", "200 g", "330ml", "1.5L", etc.
    final lower = servingSize.toLowerCase().trim();
    double value = 100.0; // Default
    String unit = 'g'; // Default

    final regex = RegExp(r'([\d\.]+)\s*([a-z]+)');
    final match = regex.firstMatch(lower);

    if (match != null) {
      value = double.tryParse(match.group(1) ?? '100') ?? 100.0;
      final unitStr = match.group(2) ?? 'g';

      if (unitStr.contains('kg')) {
        value *= 1000;
        unit = 'g';
      } else if (unitStr.contains('mg')) {
        value /= 1000;
        unit = 'g';
      } else if (unitStr.contains('l') &&
          !unitStr.contains('m') &&
          !unitStr.contains('d') &&
          !unitStr.contains('c')) {
        // Liters
        if (unitStr == 'l' || unitStr == 'liter' || unitStr == 'liters') {
          value *= 1000;
          unit = 'ml';
        }
      } else if (unitStr.contains('oz')) {
        if (unitStr.contains('fl')) {
          value *= 29.5735;
          unit = 'ml';
        } else {
          value *= 28.3495;
          unit = 'g';
        }
      } else {
        // Assume standard g or ml
        if (unitStr.contains('m') && unitStr.contains('l')) {
          unit = 'ml';
        } else {
          unit = 'g';
        }
      }
    }

    return (value: value, unit: unit);
  }

  void _openEditMealScreen(bool usesImperialUnits) {
    // TODO
    Navigator.of(context).pushNamed(NavigationOptions.editMealRoute,
        arguments: EditMealScreenArguments(
          _day,
          MealEntity.empty(),
          _mealType.getIntakeType(),
          usesImperialUnits,
        ));
  }
}

class AddMealScreenArguments {
  final AddMealType mealType;
  final DateTime day;

  AddMealScreenArguments(this.mealType, this.day);
}
