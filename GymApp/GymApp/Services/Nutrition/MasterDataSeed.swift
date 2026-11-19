import Foundation

public struct MasterDataSeed {
    public static let targetKcal: Double = 2500.0
    public static let targetProtein: Double = 160.0
    public static let targetCarbs: Double = 260.0
    public static let targetFat: Double = 65.0

    private static let rawCatalogJSON = "[{\"id\": \"food_1787510995469_1\", \"name\": \"Bio Zwiebeln\", \"brand\": \"Barilla\", \"barcode\": \"\", \"defaultPackQty\": 1000.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 72.0, \"protein100g\": 1.4, \"carbs100g\": 6.2, \"fat100g\": 3.7, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510995500_2\", \"name\": \"Bio Zuckermais\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 400.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 86.0, \"protein100g\": 3.2, \"carbs100g\": 16.0, \"fat100g\": 1.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510995665_3\", \"name\": \"EIER BH OKT\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 10.0, \"defaultPrice\": 2.49, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 140.0, \"protein100g\": 12.5, \"carbs100g\": 0.7, \"fat100g\": 9.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996021_4\", \"name\": \"Greenl. Spinat NG\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 800.0, \"defaultPrice\": 1.89, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 23.0, \"protein100g\": 2.8, \"carbs100g\": 0.8, \"fat100g\": 0.4, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996075_5\", \"name\": \"Penne Vollk. NG\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.85, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 350.0, \"protein100g\": 13.0, \"carbs100g\": 65.0, \"fat100g\": 2.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996257_6\", \"name\": \"Rote Linsen\", \"brand\": \"dmBio\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.45, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 334.0, \"protein100g\": 19.0, \"carbs100g\": 54.0, \"fat100g\": 2.1, \"fiber100g\": 0.0, \"nutriscore\": \"d\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996316_7\", \"name\": \"Granola Haferflocken\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.69, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 370.0, \"protein100g\": 13.5, \"carbs100g\": 58.7, \"fat100g\": 7.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996422_8\", \"name\": \"PENNY Kidneyb. NG\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 130.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 110.0, \"protein100g\": 8.5, \"carbs100g\": 15.0, \"fat100g\": 0.6, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787510996764_9\", \"name\": \"Pizza Tomaten\", \"brand\": \"Mutti\", \"barcode\": \"\", \"defaultPackQty\": 400.0, \"defaultPrice\": 0.65, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 36.0, \"protein100g\": 1.6, \"carbs100g\": 5.4, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511011995_10\", \"name\": \"Fr\\u00fchkartoffeln\", \"brand\": \"Coop, Naturaplan\", \"barcode\": \"\", \"defaultPackQty\": 1562.0, \"defaultPrice\": 3.58, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 75.0, \"protein100g\": 2.0, \"carbs100g\": 16.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511012164_11\", \"name\": \"Snickers Eisriegel\", \"brand\": \"SNICKERS\", \"barcode\": \"\", \"defaultPackQty\": 5.0, \"defaultPrice\": 6.57, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 342.0, \"protein100g\": 5.9, \"carbs100g\": 33.0, \"fat100g\": 20.0, \"fiber100g\": 0.0, \"nutriscore\": \"e\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511012274_12\", \"name\": \"San Fab. Pizzato\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.18, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 25.0, \"protein100g\": 1.2, \"carbs100g\": 4.0, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511012382_13\", \"name\": \"Naturgut Bio M\\u00f6hren\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 1000.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 39.0, \"protein100g\": 1.0, \"carbs100g\": 7.5, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511014554_14\", \"name\": \"M\\u00f6hren\", \"brand\": \"Freshona, Kleine Dosen\", \"barcode\": \"\", \"defaultPackQty\": 2000.0, \"defaultPrice\": 2.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 50.0, \"protein100g\": 2.8, \"carbs100g\": 6.9, \"fat100g\": 0.3, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511014635_15\", \"name\": \"Apfel rot Braeburn Deutschland\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 52.0, \"protein100g\": 0.3, \"carbs100g\": 12.0, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511014808_16\", \"name\": \"Apfel gr\\u00fcn\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.79, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 52.0, \"protein100g\": 0.3, \"carbs100g\": 12.0, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511014955_17\", \"name\": \"Marktliebe Avocado\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 2.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 160.0, \"protein100g\": 2.0, \"carbs100g\": 2.0, \"fat100g\": 15.0, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015202_18\", \"name\": \"Marktliebe Kartoffeln mehligkochend\", \"brand\": \"Marktliebe\", \"barcode\": \"\", \"defaultPackQty\": 2500.0, \"defaultPrice\": 3.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 77.0, \"protein100g\": 2.0, \"carbs100g\": 16.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015393_19\", \"name\": \"Marktliebe Kartoffeln vorw.festk.\", \"brand\": \"Marktliebe\", \"barcode\": \"\", \"defaultPackQty\": 4000.0, \"defaultPrice\": 4.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 77.0, \"protein100g\": 2.0, \"carbs100g\": 16.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015576_20\", \"name\": \"Kartoffeln fk. lose Zypern\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 77.0, \"protein100g\": 2.0, \"carbs100g\": 16.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015651_21\", \"name\": \"Best Moments Mini Cherry Rispentomaten\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 300.0, \"defaultPrice\": 2.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 20.0, \"protein100g\": 1.1, \"carbs100g\": 3.2, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015802_22\", \"name\": \"Marktliebe Rispentomaten Niederlande\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.19, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 20.0, \"protein100g\": 1.1, \"carbs100g\": 3.2, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015875_23\", \"name\": \"Marktliebe Eisbergsalat Deutschland\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 2.0, \"defaultPrice\": 0.89, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 15.0, \"protein100g\": 1.2, \"carbs100g\": 1.8, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511015974_24\", \"name\": \"Kopfsalat Deutschland\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.19, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 15.0, \"protein100g\": 1.2, \"carbs100g\": 1.8, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016043_25\", \"name\": \"Deutsche Romana Salatherzen\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 3.0, \"defaultPrice\": 1.0, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 15.0, \"protein100g\": 1.2, \"carbs100g\": 1.8, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016156_26\", \"name\": \"Naturgut Bio Rispentomaten\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.39, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 20.0, \"protein100g\": 1.1, \"carbs100g\": 3.2, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016349_27\", \"name\": \"Berida Thunfisch in Sauce\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 150.0, \"defaultPrice\": 1.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 110.0, \"protein100g\": 25.5, \"carbs100g\": 0.0, \"fat100g\": 1.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016447_28\", \"name\": \"Landfreund Parboiled Reis\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 1000.0, \"defaultPrice\": 1.39, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 355.0, \"protein100g\": 7.5, \"carbs100g\": 77.0, \"fat100g\": 0.8, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016580_29\", \"name\": \"Landfreund Milchreis\", \"brand\": \"Landfreund, Landfreund (Penny)\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 345.0, \"protein100g\": 7.1, \"carbs100g\": 76.0, \"fat100g\": 1.1, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016695_30\", \"name\": \"Naturgut Bio Basmatireis\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.59, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 355.0, \"protein100g\": 7.5, \"carbs100g\": 77.0, \"fat100g\": 0.8, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511016847_31\", \"name\": \"M\\u00fcller's M\\u00fchle Berglinsen\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.59, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 340.0, \"protein100g\": 24.0, \"carbs100g\": 52.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511017022_32\", \"name\": \"San Fabio Gnocchi\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 155.0, \"protein100g\": 3.5, \"carbs100g\": 32.0, \"fat100g\": 0.8, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511017104_33\", \"name\": \"San Fabio Totellini bunt\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 250.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 280.0, \"protein100g\": 10.0, \"carbs100g\": 45.0, \"fat100g\": 6.0, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511017319_34\", \"name\": \"San Fabio Tortelloni Spinaci\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 250.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511017517_35\", \"name\": \"Bananen\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 600.0, \"defaultPrice\": 1.2, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 89.0, \"protein100g\": 1.1, \"carbs100g\": 22.8, \"fat100g\": 0.3, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511018163_36\", \"name\": \"Karotten\", \"brand\": \"Freshona\", \"barcode\": \"\", \"defaultPackQty\": 476.0, \"defaultPrice\": 0.66, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 47.0, \"protein100g\": 2.2, \"carbs100g\": 7.2, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511030203_37\", \"name\": \"HA-BRUSTFILET\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 396.0, \"defaultPrice\": 6.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 110.0, \"protein100g\": 23.5, \"carbs100g\": 0.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511030789_38\", \"name\": \"MINI MOZZARELLA\", \"brand\": \"GALBANI\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 207.0, \"protein100g\": 17.0, \"carbs100g\": 1.0, \"fat100g\": 15.0, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511031243_39\", \"name\": \"SAN FABIO MINI M\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 2.0, \"defaultPrice\": 2.58, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511031655_40\", \"name\": \"WEIZEN TORTILLAS\", \"brand\": \"ja!\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 301.0, \"protein100g\": 9.1, \"carbs100g\": 53.0, \"fat100g\": 4.9, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"REWE\"}, {\"id\": \"food_1787511043431_41\", \"name\": \"Kichererbsenwaf.\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.35, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 380.0, \"protein100g\": 20.0, \"carbs100g\": 55.0, \"fat100g\": 6.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511043548_42\", \"name\": \"Apfel gr\\u00fcn\", \"brand\": \"Giffard\", \"barcode\": \"\", \"defaultPackQty\": 1.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 332.0, \"protein100g\": 0.0, \"carbs100g\": 83.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044029_43\", \"name\": \"Cashewkerne\", \"brand\": \"Happy Harvest\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 603.0, \"protein100g\": 21.0, \"carbs100g\": 22.0, \"fat100g\": 47.0, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044107_44\", \"name\": \"Avocado St\\u00fcck\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 1.0, \"defaultPrice\": 2.22, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 160.0, \"protein100g\": 2.0, \"carbs100g\": 2.0, \"fat100g\": 15.0, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044214_45\", \"name\": \"Kartoffeln 1,5kg\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 1500.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 77.0, \"protein100g\": 2.0, \"carbs100g\": 16.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044347_46\", \"name\": \"Zwiebeln Bravos\", \"brand\": \"Marktliebe\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 40.0, \"protein100g\": 1.2, \"carbs100g\": 8.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044429_47\", \"name\": \"Paprika rot\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 400.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 31.0, \"protein100g\": 1.0, \"carbs100g\": 6.0, \"fat100g\": 0.3, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044614_48\", \"name\": \"SKYR NATUR\", \"brand\": \"alpro\", \"barcode\": \"\", \"defaultPackQty\": 5.0, \"defaultPrice\": 7.45, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 65.0, \"protein100g\": 5.6, \"carbs100g\": 2.2, \"fat100g\": 3.3, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044713_49\", \"name\": \"SPEISEQUARK MAG.\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 4.0, \"defaultPrice\": 5.56, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 66.0, \"protein100g\": 12.0, \"carbs100g\": 4.1, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044764_50\", \"name\": \"Iglo Spinat\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 3.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 23.0, \"protein100g\": 2.8, \"carbs100g\": 0.8, \"fat100g\": 0.4, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511044863_51\", \"name\": \"Naturgut Kaiserg\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 4.0, \"defaultPrice\": 10.76, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 35.0, \"protein100g\": 2.5, \"carbs100g\": 4.0, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511045065_52\", \"name\": \"Corny Haferkraft\", \"brand\": \"CORNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 339.0, \"protein100g\": 7.7, \"carbs100g\": 62.3, \"fat100g\": 10.6, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511045854_53\", \"name\": \"NG Bio Leinsamen\", \"brand\": \"dmBio\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.55, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 540.0, \"protein100g\": 22.0, \"carbs100g\": 3.0, \"fat100g\": 43.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511045986_54\", \"name\": \"PAPRIKA EDELS\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.85, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 31.0, \"protein100g\": 1.0, \"carbs100g\": 6.0, \"fat100g\": 0.3, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046504_55\", \"name\": \"MM Peanut Butter\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 1.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 524.0, \"protein100g\": 9.5, \"carbs100g\": 57.1, \"fat100g\": 28.6, \"fiber100g\": 0.0, \"nutriscore\": \"e\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046569_56\", \"name\": \"PENNY Thunfisch\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 5.0, \"defaultPrice\": 6.95, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 110.0, \"protein100g\": 25.5, \"carbs100g\": 0.0, \"fat100g\": 1.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046628_57\", \"name\": \"Bonduelle Mais\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 140.0, \"defaultPrice\": 5.37, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 80.0, \"protein100g\": 2.9, \"carbs100g\": 14.5, \"fat100g\": 1.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046734_58\", \"name\": \"Rahm Spinat\", \"brand\": \"Pantry\", \"barcode\": \"\", \"defaultPackQty\": 900.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 23.0, \"protein100g\": 2.8, \"carbs100g\": 0.8, \"fat100g\": 0.4, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046734_59\", \"name\": \"Weizen Tortillas\", \"brand\": \"Pantry\", \"barcode\": \"26605807\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 303.0, \"protein100g\": 9.0, \"carbs100g\": 53.0, \"fat100g\": 5.7, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046768_60\", \"name\": \"Chili Gew\\u00fcrzzubereitung (scharf)\", \"brand\": \"Pantry\", \"barcode\": \"4260024160227\", \"defaultPackQty\": 250.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 315.0, \"protein100g\": 14.0, \"carbs100g\": 10.0, \"fat100g\": 16.0, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511046808_61\", \"name\": \"Fleisch Gew\\u00fcrzsalz\", \"brand\": \"Pantry\", \"barcode\": \"4260024160210\", \"defaultPackQty\": 400.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 110.0, \"protein100g\": 8.0, \"carbs100g\": 1.9, \"fat100g\": 3.8, \"fiber100g\": 0.0, \"nutriscore\": \"unknown\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511047086_62\", \"name\": \"Pfeffer Schwarz gemahlen\", \"brand\": \"Bio Wagner\", \"barcode\": \"4260024165604\", \"defaultPackQty\": 140.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"not-applicable\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511047278_63\", \"name\": \"Paprika Edels\\u00fc\\u00df\", \"brand\": \"Carat\", \"barcode\": \"4260024160500\", \"defaultPackQty\": 125.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 31.0, \"protein100g\": 1.0, \"carbs100g\": 6.0, \"fat100g\": 0.3, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787511047339_64\", \"name\": \"Natives Oliven\\u00f6l Extra\", \"brand\": \"Gut & G\\u00fcnstig\", \"barcode\": \"4311596421626\", \"defaultPackQty\": 750.0, \"defaultPrice\": 0.0, \"currentStockQty\": 0.0, \"unit\": \"ml\", \"kcal100g\": 822.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 91.3, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_schinkenwuerfel\", \"name\": \"Schinkenw\\u00fcrfel mager (2% Fett)\", \"brand\": \"PENNY / Ja!\", \"barcode\": \"\", \"defaultPackQty\": 150.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 120.0, \"protein100g\": 22.0, \"carbs100g\": 1.0, \"fat100g\": 3.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_vollkornbrot\", \"name\": \"Vollkornbrot geschnitten\", \"brand\": \"PENNY / K-Classic\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 195.0, \"protein100g\": 6.5, \"carbs100g\": 36.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_kraeuterquark\", \"name\": \"Kr\\u00e4uterquark Magerstufe\", \"brand\": \"Milbona / PENNY\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 0.89, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 78.0, \"protein100g\": 10.5, \"carbs100g\": 3.8, \"fat100g\": 2.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_reibekaese\", \"name\": \"Gouda gerieben (light)\", \"brand\": \"PENNY / Milbona\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 1.69, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 260.0, \"protein100g\": 30.0, \"carbs100g\": 1.0, \"fat100g\": 15.0, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_couscous\", \"name\": \"Couscous\", \"brand\": \"Naturgut / PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 350.0, \"protein100g\": 12.0, \"carbs100g\": 70.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_feta\", \"name\": \"Feta / Hirtenk\\u00e4se light\", \"brand\": \"PENNY / Salakis\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 1.79, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 175.0, \"protein100g\": 18.0, \"carbs100g\": 1.0, \"fat100g\": 11.0, \"fiber100g\": 0.0, \"nutriscore\": \"c\", \"store\": \"PENNY\"}, {\"id\": \"food_creme_fraiche\", \"name\": \"Cr\\u00e8me fra\\u00eeche l\\u00e9g\\u00e8re\", \"brand\": \"Milbona / PENNY\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 0.89, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 160.0, \"protein100g\": 3.0, \"carbs100g\": 4.0, \"fat100g\": 15.0, \"fiber100g\": 0.0, \"nutriscore\": \"d\", \"store\": \"PENNY\"}, {\"id\": \"food_tk_gemuese\", \"name\": \"TK-Gem\\u00fcsemischung\", \"brand\": \"PENNY / K-Classic\", \"barcode\": \"\", \"defaultPackQty\": 750.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 35.0, \"protein100g\": 2.0, \"carbs100g\": 5.0, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_rote_bete_saft\", \"name\": \"Bio Rote-Bete-Saft (NO3 Nitrat Booster)\", \"brand\": \"Alnatura / PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.29, \"currentStockQty\": 0.0, \"unit\": \"ml\", \"kcal100g\": 38.0, \"protein100g\": 1.0, \"carbs100g\": 8.5, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_omega3\", \"name\": \"Omega-3 Fisch\\u00f6l Kapseln (EPA/DHA)\", \"brand\": \"ESN / Amazon\", \"barcode\": \"\", \"defaultPackQty\": 120.0, \"defaultPrice\": 14.99, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 800.0, \"protein100g\": 18.0, \"carbs100g\": 0.0, \"fat100g\": 75.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"ESN\"}, {\"id\": \"food_1787584551166_75\", \"name\": \"Magerquark Speisequark\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.89, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 67.0, \"protein100g\": 12.0, \"carbs100g\": 4.3, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_76\", \"name\": \"Frische Eier Bodenhaltung M\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 10.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 143.0, \"protein100g\": 12.8, \"carbs100g\": 0.7, \"fat100g\": 9.9, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_77\", \"name\": \"Kr\\u00e4uterquark leicht\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 0.69, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 80.0, \"protein100g\": 9.0, \"carbs100g\": 4.0, \"fat100g\": 2.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_78\", \"name\": \"Schinkenw\\u00fcrfel mager 2% Fett\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 250.0, \"defaultPrice\": 1.79, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 125.0, \"protein100g\": 25.0, \"carbs100g\": 1.0, \"fat100g\": 2.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_79\", \"name\": \"H\\u00e4hnchenbrustfilet frisch\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 400.0, \"defaultPrice\": 3.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 106.0, \"protein100g\": 23.0, \"carbs100g\": 0.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_80\", \"name\": \"Geriebener Gouda leicht\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 200.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 260.0, \"protein100g\": 30.0, \"carbs100g\": 0.5, \"fat100g\": 16.0, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_81\", \"name\": \"Gnocchi di Patate K\\u00fchlregal\", \"brand\": \"San Fabio / PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 155.0, \"protein100g\": 3.5, \"carbs100g\": 33.0, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_82\", \"name\": \"Thunfisch im eigenen Saft\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 130.0, \"defaultPrice\": 1.19, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 110.0, \"protein100g\": 25.5, \"carbs100g\": 0.0, \"fat100g\": 0.8, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_83\", \"name\": \"Kichererbsen Dose\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 240.0, \"defaultPrice\": 0.69, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 120.0, \"protein100g\": 7.0, \"carbs100g\": 17.0, \"fat100g\": 2.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_84\", \"name\": \"Vollkorn Wraps\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 370.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 298.0, \"protein100g\": 8.9, \"carbs100g\": 51.0, \"fat100g\": 4.8, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_85\", \"name\": \"Echtes Vollkornbrot Roggen\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 195.0, \"protein100g\": 6.0, \"carbs100g\": 38.0, \"fat100g\": 1.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_86\", \"name\": \"Speisekartoffeln festkochend 2.5kg\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 2500.0, \"defaultPrice\": 2.29, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 75.0, \"protein100g\": 2.0, \"carbs100g\": 15.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_87\", \"name\": \"Zarte Haferflocken\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.69, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 370.0, \"protein100g\": 13.5, \"carbs100g\": 58.0, \"fat100g\": 7.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_88\", \"name\": \"TK-Beerenmischung\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 42.0, \"protein100g\": 1.0, \"carbs100g\": 6.5, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787584551166_89\", \"name\": \"Salatgurke frisch\", \"brand\": \"PENNY\", \"barcode\": \"\", \"defaultPackQty\": 1.0, \"defaultPrice\": 0.69, \"currentStockQty\": 0.0, \"unit\": \"St\\u00fcck\", \"kcal100g\": 15.0, \"protein100g\": 0.7, \"carbs100g\": 2.0, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"cat-tomaten-penny\", \"name\": \"Gehackte Tomaten in Tomatensaft\", \"brand\": \"PENNY / San Fabio\", \"barcode\": \"21286087\", \"defaultPackQty\": 400.0, \"defaultPrice\": 0.79, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 22.0, \"protein100g\": 1.1, \"carbs100g\": 3.7, \"fat100g\": 0.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"cat-kokosmilch-aldi\", \"name\": \"Kokosmilch fettreduziert (Light)\", \"brand\": \"Asia Green Garden / ALDI\", \"barcode\": \"4061458070461\", \"defaultPackQty\": 400.0, \"defaultPrice\": 0.99, \"currentStockQty\": 1.0, \"unit\": \"ml\", \"kcal100g\": 121.0, \"protein100g\": 0.7, \"carbs100g\": 1.4, \"fat100g\": 12.0, \"fiber100g\": 0.0, \"nutriscore\": \"b\", \"store\": \"Aldi\"}, {\"id\": \"cat-erdnussbutter-20166076\", \"name\": \"Erdnussbutter Creamy / Crunchy\", \"brand\": \"Markenqualit\\u00e4t\", \"barcode\": \"20166076\", \"defaultPackQty\": 350.0, \"defaultPrice\": 2.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 600.0, \"protein100g\": 28.0, \"carbs100g\": 12.0, \"fat100g\": 50.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Supermarkt\"}, {\"id\": \"cat-rote-linsen\", \"name\": \"Rote Linsen getrocknet\", \"brand\": \"Bio / Standard\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 1.49, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 340.0, \"protein100g\": 25.0, \"carbs100g\": 54.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"cat-basmati-reis-191g\", \"name\": \"Basmati Reis Spitzenqualit\\u00e4t\", \"brand\": \"Golden Sun / Standard\", \"barcode\": \"\", \"defaultPackQty\": 1000.0, \"defaultPrice\": 1.99, \"currentStockQty\": 0.0, \"unit\": \"g\", \"kcal100g\": 358.0, \"protein100g\": 8.5, \"carbs100g\": 78.0, \"fat100g\": 1.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"supp-magnesium-bisglycinat\", \"name\": \"Magnesium-Bisglycinat (PM Schlaf & Wind-Down)\", \"brand\": \"Evidenzbasiert / Reinsubstanz\", \"barcode\": \"\", \"defaultPackQty\": 120.0, \"defaultPrice\": 19.99, \"currentStockQty\": 60.0, \"unit\": \"Kapseln\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"supp-magnesium-malat\", \"name\": \"Magnesium-Malat (AM Energie & ATP-Synthese)\", \"brand\": \"Reinsubstanz\", \"barcode\": \"\", \"defaultPackQty\": 120.0, \"defaultPrice\": 19.99, \"currentStockQty\": 60.0, \"unit\": \"Kapseln\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"supp-vitamin-d3-k2\", \"name\": \"Vitamin D3 + K2 (MK-7) Tropfen\", \"brand\": \"High Potency\", \"barcode\": \"\", \"defaultPackQty\": 50.0, \"defaultPrice\": 17.9, \"currentStockQty\": 30.0, \"unit\": \"ml\", \"kcal100g\": 890.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 99.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"supp-omega-3-tg\", \"name\": \"Omega-3 Fisch\\u00f6l / Algen\\u00f6l (Triglycerid-Form)\", \"brand\": \"High EPA/DHA\", \"barcode\": \"\", \"defaultPackQty\": 120.0, \"defaultPrice\": 24.9, \"currentStockQty\": 90.0, \"unit\": \"Kapseln\", \"kcal100g\": 900.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 100.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"supp-rhodiola-rosea\", \"name\": \"Rhodiola Rosea Extrakt (Rosenwurz Adaptogen)\", \"brand\": \"Standardisiert (3% Rosavine)\", \"barcode\": \"\", \"defaultPackQty\": 90.0, \"defaultPrice\": 16.5, \"currentStockQty\": 45.0, \"unit\": \"Kapseln\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"supp-beta-alanin\", \"name\": \"Beta-Alanin Pulver / Kapseln\", \"brand\": \"Creapure / Standard\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 14.99, \"currentStockQty\": 250.0, \"unit\": \"g\", \"kcal100g\": 392.0, \"protein100g\": 98.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Amazon\"}, {\"id\": \"supp-kreatin-monohydrat\", \"name\": \"Kreatin Monohydrat (Creapure)\", \"brand\": \"100% Reines Creapure\", \"barcode\": \"\", \"defaultPackQty\": 500.0, \"defaultPrice\": 19.99, \"currentStockQty\": 300.0, \"unit\": \"g\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Amazon\"}, {\"id\": \"supp-whey-isolat\", \"name\": \"Whey Isolat / Protein Pulver Vanille\", \"brand\": \"Premium Isolat 90%\", \"barcode\": \"\", \"defaultPackQty\": 1000.0, \"defaultPrice\": 29.99, \"currentStockQty\": 500.0, \"unit\": \"g\", \"kcal100g\": 371.0, \"protein100g\": 88.0, \"carbs100g\": 2.5, \"fat100g\": 1.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Amazon\"}, {\"id\": \"supp-rote-bete-konzentrat\", \"name\": \"Rote-Bete-Saft-Konzentrat (140 ml NO3- Booster)\", \"brand\": \"Biotta / Rote Bete Sport\", \"barcode\": \"\", \"defaultPackQty\": 140.0, \"defaultPrice\": 2.29, \"currentStockQty\": 4.0, \"unit\": \"ml\", \"kcal100g\": 50.0, \"protein100g\": 1.5, \"carbs100g\": 10.5, \"fat100g\": 0.1, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"DM\"}, {\"id\": \"supp-zink-bisglycinat\", \"name\": \"Zink-Bisglycinat 25mg\", \"brand\": \"Reinsubstanz\", \"barcode\": \"\", \"defaultPackQty\": 120.0, \"defaultPrice\": 12.9, \"currentStockQty\": 60.0, \"unit\": \"Kapseln\", \"kcal100g\": 0.0, \"protein100g\": 0.0, \"carbs100g\": 0.0, \"fat100g\": 0.0, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"Apotheke\"}, {\"id\": \"food_1787655672345_105\", \"name\": \"Kichererbsen (Greenland / PENNY)\", \"brand\": \"Penny Greenland\", \"barcode\": \"26358741\", \"defaultPackQty\": 400.0, \"defaultPrice\": 0.89, \"currentStockQty\": 1.0, \"unit\": \"g\", \"kcal100g\": 127.0, \"protein100g\": 7.3, \"carbs100g\": 16.0, \"fat100g\": 2.2, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787655672345_106\", \"name\": \"Bio Hartweizen Couscous (Natur Gut)\", \"brand\": \"PENNY / Natur Gut\", \"barcode\": \"25794120\", \"defaultPackQty\": 750.0, \"defaultPrice\": 1.49, \"currentStockQty\": 1.0, \"unit\": \"g\", \"kcal100g\": 349.0, \"protein100g\": 12.0, \"carbs100g\": 70.0, \"fat100g\": 1.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}, {\"id\": \"food_1787655672345_107\", \"name\": \"Passierte Tomaten (San Fabio)\", \"brand\": \"San Fabio / PENNY\", \"barcode\": \"22559142\", \"defaultPackQty\": 500.0, \"defaultPrice\": 0.79, \"currentStockQty\": 1.0, \"unit\": \"g\", \"kcal100g\": 27.0, \"protein100g\": 1.8, \"carbs100g\": 3.8, \"fat100g\": 0.5, \"fiber100g\": 0.0, \"nutriscore\": \"a\", \"store\": \"PENNY\"}]"
    private static let rawTemplatesJSON = "[{\"id\": \"rec_1_gnocchi\", \"name\": \"1. AirFryer-Gnocchi mit Gem\\u00fcse (\\u201eKnusper-Pfanne\\u201c)\", \"category\": \"Warm Roast\", \"ingredients\": [{\"id\": \"ing_food_1787511017022_32_0\", \"pantryItemId\": \"food_1787511017022_32\", \"name\": \"San Fabio Gnocchi\", \"grams\": 500.0}, {\"id\": \"ing_food_tk_gemuese_1\", \"pantryItemId\": \"food_tk_gemuese\", \"name\": \"TK-Gem\\u00fcsemischung\", \"grams\": 150.0}, {\"id\": \"ing_food_1787511047339_64_2\", \"pantryItemId\": \"food_1787511047339_64\", \"name\": \"Natives Oliven\\u00f6l Extra\", \"grams\": 10.0}]}, {\"id\": \"rec_2_ruehrei\", \"name\": \"2. Protein-R\\u00fchrei mit Schinken & Vollkornbrot\", \"category\": \"Breakfast / Sandwich\", \"ingredients\": [{\"id\": \"ing_food_1787510995665_3_0\", \"pantryItemId\": \"food_1787510995665_3\", \"name\": \"EIER BH OKT\", \"grams\": 220.0}, {\"id\": \"ing_food_schinkenwuerfel_1\", \"pantryItemId\": \"food_schinkenwuerfel\", \"name\": \"Schinkenw\\u00fcrfel mager (2% Fett)\", \"grams\": 50.0}, {\"id\": \"ing_food_vollkornbrot_2\", \"pantryItemId\": \"food_vollkornbrot\", \"name\": \"Vollkornbrot geschnitten\", \"grams\": 120.0}]}, {\"id\": \"rec_3_kumpir\", \"name\": \"3. Ofen-Kumpir (Gef\\u00fcllte Riesen-Kartoffeln)\", \"category\": \"Warm Roast\", \"ingredients\": [{\"id\": \"ing_food_1787511011995_10_0\", \"pantryItemId\": \"food_1787511011995_10\", \"name\": \"Fr\\u00fchkartoffeln\", \"grams\": 400.0}, {\"id\": \"ing_food_1787510995469_1_1\", \"pantryItemId\": \"food_1787510995469_1\", \"name\": \"Bio Zwiebeln\", \"grams\": 150.0}, {\"id\": \"ing_food_reibekaese_2\", \"pantryItemId\": \"food_reibekaese\", \"name\": \"Gouda gerieben (light)\", \"grams\": 30.0}]}, {\"id\": \"rec_4_couscous\", \"name\": \"4. Blitz-Couscous-Pfanne mit Tomaten & Feta\", \"category\": \"Soups & Stews\", \"ingredients\": [{\"id\": \"ing_food_couscous_0\", \"pantryItemId\": \"food_couscous\", \"name\": \"Couscous\", \"grams\": 120.0}, {\"id\": \"ing_food_1787510996764_9_1\", \"pantryItemId\": \"food_1787510996764_9\", \"name\": \"Pizza Tomaten\", \"grams\": 240.0}, {\"id\": \"ing_food_feta_2\", \"pantryItemId\": \"food_feta\", \"name\": \"Feta / Hirtenk\\u00e4se light\", \"grams\": 50.0}]}, {\"id\": \"rec_5_wraps\", \"name\": \"5. Mexikanische Knusper-H\\u00e4hnchen-Wraps\", \"category\": \"Sandwiches & Wraps\", \"ingredients\": [{\"id\": \"ing_food_1787511031655_40_0\", \"pantryItemId\": \"food_1787511031655_40\", \"name\": \"WEIZEN TORTILLAS\", \"grams\": 120.0}, {\"id\": \"ing_food_1787511030203_37_1\", \"pantryItemId\": \"food_1787511030203_37\", \"name\": \"HA-BRUSTFILET\", \"grams\": 120.0}, {\"id\": \"ing_food_1787511015875_23_2\", \"pantryItemId\": \"food_1787511015875_23\", \"name\": \"Marktliebe Eisbergsalat Deutschland\", \"grams\": 50.0}]}, {\"id\": \"rec_6_tuna_melt\", \"name\": \"6. AirFryer Tuna-Melt Toasties\", \"category\": \"Sandwiches\", \"ingredients\": [{\"id\": \"ing_food_vollkornbrot_0\", \"pantryItemId\": \"food_vollkornbrot\", \"name\": \"Vollkornbrot geschnitten\", \"grams\": 120.0}, {\"id\": \"ing_food_1787511016349_27_1\", \"pantryItemId\": \"food_1787511016349_27\", \"name\": \"Berida Thunfisch in Sauce\", \"grams\": 150.0}, {\"id\": \"ing_food_reibekaese_2\", \"pantryItemId\": \"food_reibekaese\", \"name\": \"Gouda gerieben (light)\", \"grams\": 30.0}]}, {\"id\": \"rec_7_kichererbsen\", \"name\": \"7. Knusprige Paprika-Kichererbsen mit Kr\\u00e4uterquark\", \"category\": \"High-Fiber Bowl\", \"ingredients\": [{\"id\": \"ing_food_1787511043431_41_0\", \"pantryItemId\": \"food_1787511043431_41\", \"name\": \"Kichererbsenwaf.\", \"grams\": 240.0}, {\"id\": \"ing_food_1787510995469_1_1\", \"pantryItemId\": \"food_1787510995469_1\", \"name\": \"Bio Zwiebeln\", \"grams\": 150.0}]}, {\"id\": \"rec_8_shakshuka\", \"name\": \"8. Stuben-Shakshuka mit roten Linsen & 3 Eiern\", \"category\": \"Soups & Stews\", \"ingredients\": [{\"id\": \"ing_food_1787510996257_6_0\", \"pantryItemId\": \"food_1787510996257_6\", \"name\": \"Rote Linsen\", \"grams\": 80.0}, {\"id\": \"ing_food_1787510996764_9_1\", \"pantryItemId\": \"food_1787510996764_9\", \"name\": \"Pizza Tomaten\", \"grams\": 200.0}, {\"id\": \"ing_food_1787510995665_3_2\", \"pantryItemId\": \"food_1787510995665_3\", \"name\": \"EIER BH OKT\", \"grams\": 165.0}]}, {\"id\": \"rec_9_wedges\", \"name\": \"9. AirFryer H\\u00e4hnchen-Kartoffel Wedges\", \"category\": \"Warm Roast\", \"ingredients\": [{\"id\": \"ing_food_1787511011995_10_0\", \"pantryItemId\": \"food_1787511011995_10\", \"name\": \"Fr\\u00fchkartoffeln\", \"grams\": 300.0}, {\"id\": \"ing_food_1787511030203_37_1\", \"pantryItemId\": \"food_1787511030203_37\", \"name\": \"HA-BRUSTFILET\", \"grams\": 120.0}]}, {\"id\": \"rec_10_baked_oats\", \"name\": \"10. Warmes Baked-Protein-Oatmeal aus dem AirFryer\", \"category\": \"Sweet Breakfast\", \"ingredients\": [{\"id\": \"ing_food_1787510996316_7_0\", \"pantryItemId\": \"food_1787510996316_7\", \"name\": \"Granola Haferflocken\", \"grams\": 80.0}, {\"id\": \"ing_food_1787510995665_3_1\", \"pantryItemId\": \"food_1787510995665_3\", \"name\": \"EIER BH OKT\", \"grams\": 55.0}, {\"id\": \"ing_food_beeren_2\", \"pantryItemId\": \"food_beeren\", \"name\": \"TK-Beerenmischung\", \"grams\": 80.0}, {\"id\": \"ing_food_whey_3\", \"pantryItemId\": \"food_whey\", \"name\": \"Whey Protein Isolat\", \"grams\": 20.0}]}, {\"id\": \"recipe-kokos-tomaten-dal\", \"name\": \"15. Cremiges Kokos-Tomaten-Dal mit 191g Basmati-Reis & Erdnussbutter\", \"category\": \"Soups & Stews\", \"ingredients\": [{\"id\": \"ing_cat-rote-linsen_0\", \"pantryItemId\": \"cat-rote-linsen\", \"name\": \"Rote Linsen getrocknet\", \"grams\": 180.0}, {\"id\": \"ing_cat-basmati-reis-191g_1\", \"pantryItemId\": \"cat-basmati-reis-191g\", \"name\": \"Basmati Reis Spitzenqualit\\u00e4t\", \"grams\": 191.0}, {\"id\": \"ing_cat-tomaten-penny_2\", \"pantryItemId\": \"cat-tomaten-penny\", \"name\": \"Gehackte Tomaten in Tomatensaft\", \"grams\": 400.0}, {\"id\": \"ing_cat-kokosmilch-aldi_3\", \"pantryItemId\": \"cat-kokosmilch-aldi\", \"name\": \"Kokosmilch fettreduziert (Light)\", \"grams\": 200.0}, {\"id\": \"ing_cat-erdnussbutter-20166076_4\", \"pantryItemId\": \"cat-erdnussbutter-20166076\", \"name\": \"Erdnussbutter Creamy / Crunchy\", \"grams\": 31.0}]}]"
    private static let rawShoppingJSON = "[{\"id\": \"shop_1\", \"pantryItemId\": \"shop_1\", \"name\": \"Magerquark Speisequark\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 0.89, \"store\": \"PENNY\", \"quantity\": 4, \"isChecked\": false}, {\"id\": \"shop_2\", \"pantryItemId\": \"shop_2\", \"name\": \"Frische Eier Bodenhaltung M\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 10.0, \"price\": 1.99, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_3\", \"pantryItemId\": \"shop_3\", \"name\": \"Kr\\u00e4uterquark leicht\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 200.0, \"price\": 0.69, \"store\": \"PENNY\", \"quantity\": 2, \"isChecked\": false}, {\"id\": \"shop_4\", \"pantryItemId\": \"shop_4\", \"name\": \"Schinkenw\\u00fcrfel mager 2% Fett\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 250.0, \"price\": 1.79, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_5\", \"pantryItemId\": \"shop_5\", \"name\": \"H\\u00e4hnchenbrustfilet frisch\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 400.0, \"price\": 3.99, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_6\", \"pantryItemId\": \"shop_6\", \"name\": \"Geriebener Gouda leicht\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 200.0, \"price\": 1.49, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_7\", \"pantryItemId\": \"shop_7\", \"name\": \"Gnocchi di Patate K\\u00fchlregal\", \"brand\": \"San Fabio / PENNY\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 0.99, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_8\", \"pantryItemId\": \"shop_8\", \"name\": \"Thunfisch im eigenen Saft\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 130.0, \"price\": 1.19, \"store\": \"PENNY\", \"quantity\": 3, \"isChecked\": false}, {\"id\": \"shop_9\", \"pantryItemId\": \"shop_9\", \"name\": \"Kichererbsen Dose\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 240.0, \"price\": 0.69, \"store\": \"PENNY\", \"quantity\": 2, \"isChecked\": false}, {\"id\": \"shop_10\", \"pantryItemId\": \"shop_10\", \"name\": \"Vollkorn Wraps\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 370.0, \"price\": 1.49, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_11\", \"pantryItemId\": \"shop_11\", \"name\": \"Echtes Vollkornbrot Roggen\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 0.99, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_12\", \"pantryItemId\": \"shop_12\", \"name\": \"Speisekartoffeln festkochend 2.5kg\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 2500.0, \"price\": 2.29, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_13\", \"pantryItemId\": \"shop_13\", \"name\": \"Zarte Haferflocken\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 0.69, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_14\", \"pantryItemId\": \"shop_14\", \"name\": \"Bananen\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 600.0, \"price\": 1.2, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_15\", \"pantryItemId\": \"shop_15\", \"name\": \"TK-Beerenmischung\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 1.99, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop_16\", \"pantryItemId\": \"shop_16\", \"name\": \"Salatgurke frisch\", \"brand\": \"PENNY\", \"barcode\": \"\", \"packQty\": 1.0, \"price\": 0.69, \"store\": \"PENNY\", \"quantity\": 1, \"isChecked\": false}, {\"id\": \"shop-1788799469281-s22n\", \"pantryItemId\": \"shop-1788799469281-s22n\", \"name\": \"Rote Linsen getrocknet\", \"brand\": \"Bio / Standard\", \"barcode\": \"\", \"packQty\": 500.0, \"price\": 1.49, \"store\": \"PENNY\", \"quantity\": 2, \"isChecked\": true}, {\"id\": \"shop-1788799469281-9uxw\", \"pantryItemId\": \"shop-1788799469281-9uxw\", \"name\": \"Basmati Reis Spitzenqualit\\u00e4t\", \"brand\": \"Golden Sun / Standard\", \"barcode\": \"\", \"packQty\": 1000.0, \"price\": 1.99, \"store\": \"PENNY\", \"quantity\": 2, \"isChecked\": true}, {\"id\": \"shop-1788799469281-wcap\", \"pantryItemId\": \"shop-1788799469281-wcap\", \"name\": \"Gehackte Tomaten in Tomatensaft\", \"brand\": \"PENNY / San Fabio\", \"barcode\": \"21286087\", \"packQty\": 400.0, \"price\": 0.79, \"store\": \"PENNY\", \"quantity\": 2, \"isChecked\": true}, {\"id\": \"shop-1788799469281-r2er\", \"pantryItemId\": \"shop-1788799469281-r2er\", \"name\": \"Kokosmilch fettreduziert (Light)\", \"brand\": \"Asia Green Garden / ALDI\", \"barcode\": \"4061458070461\", \"packQty\": 400.0, \"price\": 0.99, \"store\": \"Aldi\", \"quantity\": 2, \"isChecked\": true}, {\"id\": \"shop-1788799469281-80o4\", \"pantryItemId\": \"shop-1788799469281-80o4\", \"name\": \"Erdnussbutter Creamy / Crunchy\", \"brand\": \"Markenqualit\\u00e4t\", \"barcode\": \"20166076\", \"packQty\": 350.0, \"price\": 2.49, \"store\": \"Supermarkt\", \"quantity\": 2, \"isChecked\": true}]"

    private static let _cachedMasterCatalog: [PantryItem] = {
        var items: [PantryItem] = []
        if let data = rawCatalogJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PantryItem].self, from: data) {
            items = decoded
        }

        let pennyBakingItems: [PantryItem] = [
            PantryItem(
                id: "food_penny_butter",
                name: "Deutsche Markenbutter mildgesäuert",
                brand: "PENNY",
                barcode: "4337256214589",
                defaultPackQty: 250.0,
                defaultPrice: 1.59,
                currentStockQty: 250.0,
                unit: "g",
                kcal100g: 743.0,
                protein100g: 0.7,
                carbs100g: 0.7,
                fat100g: 82.0,
                fiber100g: 0.0,
                nutriscore: "e",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_brauner_zucker",
                name: "Brauner Rohrzucker",
                brand: "PENNY / Naturgut",
                barcode: "4337256123454",
                defaultPackQty: 500.0,
                defaultPrice: 1.49,
                currentStockQty: 500.0,
                unit: "g",
                kcal100g: 396.0,
                protein100g: 0.0,
                carbs100g: 99.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "d",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_zucker_weiss",
                name: "PENNY Zucker feine Körnung",
                brand: "PENNY",
                barcode: "4337256001288",
                defaultPackQty: 1000.0,
                defaultPrice: 1.19,
                currentStockQty: 1000.0,
                unit: "g",
                kcal100g: 400.0,
                protein100g: 0.0,
                carbs100g: 100.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "d",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_vanillezucker",
                name: "Vanillin-Zucker (10er Pack)",
                brand: "PENNY",
                barcode: "4337256552193",
                defaultPackQty: 80.0,
                defaultPrice: 0.59,
                currentStockQty: 80.0,
                unit: "g",
                kcal100g: 396.0,
                protein100g: 0.0,
                carbs100g: 99.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "d",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_weizenmehl_405",
                name: "PENNY Weizenmehl Type 405",
                brand: "PENNY",
                barcode: "4337256330012",
                defaultPackQty: 1000.0,
                defaultPrice: 0.79,
                currentStockQty: 1000.0,
                unit: "g",
                kcal100g: 348.0,
                protein100g: 10.0,
                carbs100g: 72.0,
                fat100g: 1.0,
                fiber100g: 3.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_backpulver",
                name: "Backpulver / Kaiser Natron",
                brand: "PENNY",
                barcode: "4337256778100",
                defaultPackQty: 150.0,
                defaultPrice: 0.49,
                currentStockQty: 150.0,
                unit: "g",
                kcal100g: 100.0,
                protein100g: 0.0,
                carbs100g: 24.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_feinsalz",
                name: "PENNY Jodsalz mit Fluorid",
                brand: "PENNY",
                barcode: "4337256889211",
                defaultPackQty: 500.0,
                defaultPrice: 0.29,
                currentStockQty: 500.0,
                unit: "g",
                kcal100g: 0.0,
                protein100g: 0.0,
                carbs100g: 0.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_zartbitter_schoko",
                name: "PENNY Zartbitter Schokolade 50%",
                brand: "PENNY / Choco'la",
                barcode: "4337256990342",
                defaultPackQty: 100.0,
                defaultPrice: 0.99,
                currentStockQty: 200.0,
                unit: "g",
                kcal100g: 520.0,
                protein100g: 5.5,
                carbs100g: 54.0,
                fat100g: 30.0,
                fiber100g: 7.0,
                nutriscore: "d",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_penny_backpapier",
                name: "PENNY Backpapier Zuschnitte",
                brand: "PENNY",
                barcode: "4337256112233",
                defaultPackQty: 30.0,
                defaultPrice: 1.19,
                currentStockQty: 30.0,
                unit: "Stück",
                kcal100g: 0.0,
                protein100g: 0.0,
                carbs100g: 0.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_beeren",
                name: "TK-Beerenmischung",
                brand: "Green Grocer",
                barcode: "4337256221199",
                defaultPackQty: 500.0,
                defaultPrice: 2.49,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 48.0,
                protein100g: 1.2,
                carbs100g: 8.5,
                fat100g: 0.5,
                fiber100g: 4.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_whey",
                name: "Whey Protein Isolat",
                brand: "Sports Nutrition",
                barcode: "4337256994411",
                defaultPackQty: 1000.0,
                defaultPrice: 24.99,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 375.0,
                protein100g: 85.0,
                carbs100g: 3.0,
                fat100g: 1.5,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_speisequark_magerstufe",
                name: "Speisequark Magerstufe",
                brand: "Elite",
                barcode: "4337256334412",
                defaultPackQty: 500.0,
                defaultPrice: 1.39,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 68.0,
                protein100g: 12.0,
                carbs100g: 4.0,
                fat100g: 0.2,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_haferflocken_zart",
                name: "Haferflocken zart",
                brand: "PENNY",
                barcode: "4337256554421",
                defaultPackQty: 500.0,
                defaultPrice: 0.79,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 370.0,
                protein100g: 13.5,
                carbs100g: 58.7,
                fat100g: 7.0,
                fiber100g: 10.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_erdnussbutter",
                name: "Erdnussbutter",
                brand: "MyBestVeggie",
                barcode: "4337256778811",
                defaultPackQty: 350.0,
                defaultPrice: 2.49,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 595.0,
                protein100g: 25.0,
                carbs100g: 13.0,
                fat100g: 48.0,
                fiber100g: 7.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_bluetenhonig",
                name: "Blütenhonig",
                brand: "PENNY",
                barcode: "4337256119933",
                defaultPackQty: 500.0,
                defaultPrice: 3.49,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 304.0,
                protein100g: 0.3,
                carbs100g: 82.0,
                fat100g: 0.0,
                fiber100g: 0.2,
                nutriscore: "c",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_rote_linsen_rollini",
                name: "Rote Linsen Rollini",
                brand: "PENNY",
                barcode: "4337256441199",
                defaultPackQty: 500.0,
                defaultPrice: 1.99,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 345.0,
                protein100g: 26.0,
                carbs100g: 53.0,
                fat100g: 1.5,
                fiber100g: 5.9,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_thunfischfilet",
                name: "Thunfischfilet in eigenem Saft und Aufguss",
                brand: "Berida",
                barcode: "4337256882200",
                defaultPackQty: 195.0,
                defaultPrice: 1.49,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 105.0,
                protein100g: 24.0,
                carbs100g: 0.0,
                fat100g: 1.0,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_scheibenkaese",
                name: "Scheibenkäse",
                brand: "San Fabio",
                barcode: "4337256661133",
                defaultPackQty: 150.0,
                defaultPrice: 1.89,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 340.0,
                protein100g: 25.0,
                carbs100g: 0.5,
                fat100g: 27.0,
                fiber100g: 0.0,
                nutriscore: "c",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_schwarze_bohnen",
                name: "Schwarze Bohnen",
                brand: "PENNY",
                barcode: "4337256339944",
                defaultPackQty: 400.0,
                defaultPrice: 0.99,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 115.0,
                protein100g: 8.0,
                carbs100g: 16.0,
                fat100g: 0.8,
                fiber100g: 6.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_rote_kidney_bohnen",
                name: "Rote Kidney Bohnen 200g",
                brand: "PENNY",
                barcode: "4337256228833",
                defaultPackQty: 200.0,
                defaultPrice: 0.89,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 110.0,
                protein100g: 8.5,
                carbs100g: 15.0,
                fat100g: 0.6,
                fiber100g: 6.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_ziegenkaese",
                name: "Ziegenkäse",
                brand: "PENNY",
                barcode: "4337256114477",
                defaultPackQty: 150.0,
                defaultPrice: 2.29,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 290.0,
                protein100g: 19.0,
                carbs100g: 1.0,
                fat100g: 23.0,
                fiber100g: 0.0,
                nutriscore: "c",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_delikatess_sauerkraut",
                name: "Delikatess Sauerkraut von Spreewald Prinzessin",
                brand: "Spreewald Prinzessin",
                barcode: "4337256553311",
                defaultPackQty: 500.0,
                defaultPrice: 1.29,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 19.0,
                protein100g: 1.5,
                carbs100g: 1.5,
                fat100g: 0.3,
                fiber100g: 2.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_edle_matjesfilets",
                name: "Edle Matjesfilets",
                brand: "PENNY",
                barcode: "4337256885522",
                defaultPackQty: 256.0,
                defaultPrice: 2.19,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 240.0,
                protein100g: 14.0,
                carbs100g: 0.0,
                fat100g: 20.0,
                fiber100g: 0.0,
                nutriscore: "b",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_tk_gemuese",
                name: "TK-Gemüsemischung",
                brand: "Green Grocer",
                barcode: "4337256774433",
                defaultPackQty: 750.0,
                defaultPrice: 1.79,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 45.0,
                protein100g: 2.5,
                carbs100g: 6.0,
                fat100g: 0.5,
                fiber100g: 3.2,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_schinkenwuerfel",
                name: "Schinkenwürfel mager (2% Fett)",
                brand: "Mühlenhof",
                barcode: "4337256447722",
                defaultPackQty: 150.0,
                defaultPrice: 1.99,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 108.0,
                protein100g: 21.0,
                carbs100g: 1.0,
                fat100g: 2.0,
                fiber100g: 0.0,
                nutriscore: "b",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_vollkornbrot",
                name: "Vollkornbrot geschnitten",
                brand: "Bäcker Penny",
                barcode: "4337256116633",
                defaultPackQty: 500.0,
                defaultPrice: 1.19,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 198.0,
                protein100g: 7.0,
                carbs100g: 36.0,
                fat100g: 1.5,
                fiber100g: 8.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_reibekaese",
                name: "Gouda gerieben (light)",
                brand: "San Fabio",
                barcode: "4337256558899",
                defaultPackQty: 200.0,
                defaultPrice: 1.89,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 260.0,
                protein100g: 30.0,
                carbs100g: 0.5,
                fat100g: 16.0,
                fiber100g: 0.0,
                nutriscore: "c",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_kraeuterquark",
                name: "Kräuterquark Magerstufe",
                brand: "Elite",
                barcode: "4337256331188",
                defaultPackQty: 200.0,
                defaultPrice: 0.99,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 75.0,
                protein100g: 10.5,
                carbs100g: 4.0,
                fat100g: 1.8,
                fiber100g: 0.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_couscous",
                name: "Couscous",
                brand: "Pantry",
                barcode: "4337256992211",
                defaultPackQty: 500.0,
                defaultPrice: 1.29,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 350.0,
                protein100g: 12.0,
                carbs100g: 70.0,
                fat100g: 1.5,
                fiber100g: 5.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "food_feta",
                name: "Feta / Hirtenkäse light",
                brand: "San Fabio",
                barcode: "4337256773344",
                defaultPackQty: 200.0,
                defaultPrice: 1.79,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: 175.0,
                protein100g: 18.0,
                carbs100g: 1.0,
                fat100g: 11.0,
                fiber100g: 0.0,
                nutriscore: "c",
                store: "PENNY"
            )
        ]

        for pItem in pennyBakingItems {
            if !items.contains(where: { $0.id == pItem.id }) {
                items.append(pItem)
            }
        }
        return items
    }()

    public static func getMasterCatalog() -> [PantryItem] {
        return _cachedMasterCatalog
    }

    private static let _cachedMasterTemplates: [MealTemplate] = [
        MealTemplate(
                id: "rec_1_gnocchi",
                name: "1. AirFryer-Gnocchi mit Gemuese („Knusper-Pfanne“)",
                category: "Warm Roast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787511017022_32", name: "San Fabio Gnocchi", grams: 500.0),
                    TemplateIngredient(pantryItemId: "food_tk_gemuese", name: "TK-Gemuesemischung", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_1787511047339_64", name: "Natives Olivenoel Extra", grams: 10.0)
                ],
                instructions: [
                    "AirFryer auf 190 Grad C fuer 2 Minuten vorheizen.",
                    "500 g frische Gnocchi und 150 g TK-Gemuese in eine Schuessel wiegen. Mit 1 EL Olivenoel, Meersalz, Paprikapulver und Rosmarin gruendlich vermengen.",
                    "Die marinierte Mischung gleichmaessig im Garkorb verteilen.",
                    "Bei 190 Grad C fuer 12-15 Minuten backen. Nach 7 Minuten den Korb kraeftig durchschuetteln, damit alle Gnocchi rundherum kross werden.",
                    "Heiss auf einem flachen Teller anrichten und servieren."
                ]
            ),
            MealTemplate(
                id: "rec_2_ruehrei",
                name: "2. Protein-Ruehrei mit Schinken & Vollkornbrot",
                category: "Breakfast / Sandwich",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787510995665_3", name: "EIER BH OKT", grams: 4.0),
                    TemplateIngredient(pantryItemId: "food_schinkenwuerfel", name: "Schinkenwuerfel mager (2% Fett)", grams: 50.0),
                    TemplateIngredient(pantryItemId: "food_vollkornbrot", name: "Vollkornbrot geschnitten", grams: 120.0)
                ],
                instructions: [
                    "Pfanne auf mittlerer Stufe erwaermen. 50 g magere Schinkenwuerfel ohne Fett 1-2 Minuten anbraten, bis sie duften.",
                    "4 Eier in einer Schale kurz mit einer Gabel anschlagen, mit Pfeffer und wenig Salz wuerzen.",
                    "Eiermasse in die Pfanne giessen. Bei schwacher Hitze mit dem Spatel langsam von aussen nach innen schieben, bis das Ruehrei cremig stockt.",
                    "Ruehrei auf 3 Scheiben Vollkornbrot verteilen und mit Schnittlauch garnieren."
                ]
            ),
            MealTemplate(
                id: "rec_3_kumpir",
                name: "3. Ofen-Kumpir (Gefuellte Riesen-Kartoffeln)",
                category: "Warm Roast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787511011995_10", name: "Fruehkartoffeln", grams: 400.0),
                    TemplateIngredient(pantryItemId: "food_1787510995469_1", name: "Bio Zwiebeln", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_reibekaese", name: "Gouda gerieben (light)", grams: 30.0),
                    TemplateIngredient(pantryItemId: "food_kraeuterquark", name: "Kraeuterquark Magerstufe", grams: 100.0)
                ],
                instructions: [
                    "2 grosse Kartoffeln waschen, trocken tupfen und rundherum mit einer Gabel mehrfach einstechen.",
                    "Im AirFryer bei 200 Grad C fuer 25-30 Minuten backen, bis das Innere weich ist.",
                    "Die heissen Kartoffeln laengs aufschneiden und das Innere mit einer Gabel leicht auflockern.",
                    "Gouda light in das heisse Innere streuen und mit Kraeuterquark toppen."
                ]
            ),
            MealTemplate(
                id: "rec_4_couscous",
                name: "4. Blitz-Couscous-Pfanne mit Tomaten & Feta",
                category: "Soups & Stews",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_couscous", name: "Couscous", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787510996764_9", name: "Pizza Tomaten", grams: 240.0),
                    TemplateIngredient(pantryItemId: "food_feta", name: "Feta / Hirtenkaese light", grams: 50.0)
                ],
                instructions: [
                    "120 g Couscous in einer Schuessel mit 150 ml kochendem Salzwasser uebergiessen, abdecken und 5 Minuten quellen lassen.",
                    "In einer Kasserolle 240 g Tomaten mit Kraeutern und Salz kurz erhitzen.",
                    "Couscous mit einer Gabel lockern und unter die Tomaten heben. 50 g Feta darueberkruemeln und 1 Minute anschmelzen lassen."
                ]
            ),
            MealTemplate(
                id: "rec_5_wraps",
                name: "5. Mexikanische Knusper-Haehnchen-Wraps",
                category: "Sandwiches & Wraps",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787511031655_40", name: "WEIZEN TORTILLAS", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787511030203_37", name: "HA-BRUSTFILET", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787511015875_23", name: "Marktliebe Eisbergsalat Deutschland", grams: 50.0),
                    TemplateIngredient(pantryItemId: "food_1787584551166_75", name: "Magerquark Speisequark", grams: 50.0)
                ],
                instructions: [
                    "120 g Haehnchenbrustfilet in Streifen schneiden, mit Fajita-Gewuerz marinieren und im AirFryer bei 180 Grad C fuer 10 Minuten garen.",
                    "Tortilla-Wraps auslegen, mit Magerquark bestreichen, Salat und gegarte Haehnchenstreifen mittig auflegen.",
                    "Wraps straff einrollen und fuer 2-3 Minuten bei 200 Grad C im AirFryer knusprig toasten."
                ]
            ),
            MealTemplate(
                id: "rec_6_tuna_melt",
                name: "6. AirFryer Tuna-Melt Toasties",
                category: "Sandwiches",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_vollkornbrot", name: "Vollkornbrot geschnitten", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787511016349_27", name: "Berida Thunfisch in Sauce", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_reibekaese", name: "Gouda gerieben (light)", grams: 30.0),
                    TemplateIngredient(pantryItemId: "food_1787510995500_2", name: "Bio Zuckermais", grams: 30.0)
                ],
                instructions: [
                    "150 g Thunfisch abtropfen lassen und mit Mais, Pfeffer und Oregano vermengen.",
                    "3 Scheiben Vollkornbrot mit der Masse belegen und mit 30 g Reibekaese light bestreuen.",
                    "Im AirFryer bei 185 Grad C fuer 6-8 Minuten backen, bis der Kaese goldbraun zerlaeuft."
                ]
            ),
            MealTemplate(
                id: "rec_7_kichererbsen",
                name: "7. Knusprige Paprika-Kichererbsen mit Kraeuterquark",
                category: "High-Fiber Bowl",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787584551166_83", name: "Kichererbsen Dose", grams: 240.0),
                    TemplateIngredient(pantryItemId: "food_1787510995469_1", name: "Bio Zwiebeln", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_kraeuterquark", name: "Kraeuterquark Magerstufe", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_1787511047339_64", name: "Natives Olivenoel Extra", grams: 10.0)
                ],
                instructions: [
                    "240 g Kichererbsen abspuelen und mit Kuechenpapier gruendlich trocken reiben.",
                    "Mit 1 EL Olivenoel, Paprikapulver und Meersalz vermengen.",
                    "Im AirFryer bei 195 Grad C fuer 12-15 Minuten roesten, nach 6 und 10 Minuten den Korb schuetteln.",
                    "Mit 150 g Kraeuterquark servieren."
                ]
            ),
            MealTemplate(
                id: "rec_8_shakshuka",
                name: "8. Stuben-Shakshuka mit roten Linsen & 3 Eiern",
                category: "Soups & Stews",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787510996257_6", name: "Rote Linsen", grams: 80.0),
                    TemplateIngredient(pantryItemId: "food_1787510996764_9", name: "Pizza Tomaten", grams: 200.0),
                    TemplateIngredient(pantryItemId: "food_1787510995665_3", name: "EIER BH OKT", grams: 3.0)
                ],
                instructions: [
                    "80 g rote Linsen mit 150 ml kochendem Wasser und 200 g Tomaten in die Kasserolle geben. Mit Kreuzkuemmel und Salz 7 Minuten koecheln.",
                    "3 Mulden in die Sauce druecken und 3 Eier hineinschlagen.",
                    "Deckel aufsetzen und bei kleiner Hitze 4-5 Minuten stocken lassen, bis das Eiweiss fest ist."
                ]
            ),
            MealTemplate(
                id: "rec_9_wedges",
                name: "9. AirFryer Haehnchen-Kartoffel Wedges",
                category: "Warm Roast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787511011995_10", name: "Fruehkartoffeln", grams: 300.0),
                    TemplateIngredient(pantryItemId: "food_1787511030203_37", name: "HA-BRUSTFILET", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787511047339_64", name: "Natives Olivenoel Extra", grams: 10.0)
                ],
                instructions: [
                    "300 g Kartoffeln vierteln und 120 g Haehnchenbrustfilet wuerfeln.",
                    "Mit 1 EL Olivenoel, Rosmarin und Pommesgewuerz marinieren.",
                    "Im AirFryer bei 190 Grad C fuer 18-20 Minuten backen, nach 10 Minuten kraeftig schuetteln."
                ]
            ),
            MealTemplate(
                id: "rec_10_baked_oats",
                name: "10. Warmes Baked-Protein-Oatmeal aus dem AirFryer",
                category: "Sweet Breakfast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787510996316_7", name: "Granola Haferflocken", grams: 80.0),
                    TemplateIngredient(pantryItemId: "food_1787510995665_3", name: "EIER BH OKT", grams: 1.0),
                    TemplateIngredient(pantryItemId: "food_1787584551166_88", name: "TK-Beerenmischung", grams: 80.0),
                    TemplateIngredient(pantryItemId: "supp-whey-isolat", name: "Whey Isolat / Protein Pulver Vanille", grams: 20.0)
                ],
                instructions: [
                    "80 g Haferflocken, 1 Ei, 20 g Whey Protein, Zimt und 80 ml Wasser in einer ofenfesten Schale verruehren.",
                    "80 g TK-Beeren vorsichtig unterheben.",
                    "Im AirFryer bei 175 Grad C fuer 10-12 Minuten backen, bis das Oatmeal fluffig aufgeht."
                ]
            ),
            MealTemplate(
                id: "rec_11_french_toast",
                name: "11. Anabolic French Toast (Greg Doucette Signature)",
                category: "Sweet Breakfast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_vollkornbrot", name: "Vollkornbrot geschnitten", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787510995665_3", name: "EIER BH OKT", grams: 3.0),
                    TemplateIngredient(pantryItemId: "food_1787584551166_75", name: "Magerquark Speisequark", grams: 100.0)
                ],
                instructions: [
                    "Eier mit Zimt und Suessstoff in einem tiefen Teller gruendlich verquirlen.",
                    "3 Scheiben Vollkornbrot beidseitig traenken, bis die Eimasse vollstaendig aufgesaugt ist.",
                    "Im AirFryer bei 185 Grad C fuer 6-8 Minuten goldbraun backen.",
                    "Mit 100 g Magerquark-Creme und Zimt als Topping anrichten."
                ]
            ),
            MealTemplate(
                id: "rec_12_berry_fluff",
                name: "12. Anabolic Berry Fluff Mousse",
                category: "Sweet Breakfast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787584551166_88", name: "TK-Beerenmischung", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_1787584551166_75", name: "Magerquark Speisequark", grams: 150.0),
                    TemplateIngredient(pantryItemId: "supp-whey-isolat", name: "Whey Isolat / Protein Pulver Vanille", grams: 25.0)
                ],
                instructions: [
                    "150 g gefrorene Beeren kurz mit 50 ml kaltem Wasser anpuerieren.",
                    "150 g Magerquark und 25 g Whey Protein Pulver zugeben.",
                    "Mit einem Ruehrbesen auf hoechster Stufe 3-4 Minuten schaumig schlagen, bis sich das Volumen vervielfacht.",
                    "Sofort eiskalt in einer grossen Schale servieren."
                ]
            ),
            MealTemplate(
                id: "rec_13_teriyaki",
                name: "13. Asiatische AirFryer Teriyaki Haehnchen-Pfanne",
                category: "Warm Roast",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_1787511030203_37", name: "HA-BRUSTFILET", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_tk_gemuese", name: "TK-Gemuesemischung", grams: 200.0),
                    TemplateIngredient(pantryItemId: "food_1787511047339_64", name: "Natives Olivenoel Extra", grams: 10.0)
                ],
                instructions: [
                    "120 g Haehnchenbrustfilet wuerfeln und mit Sojasauce und Pfeffer marinieren.",
                    "200 g TK-Gemuese dazugeben und gruendlich vermengen.",
                    "Im AirFryer bei 185 Grad C fuer 12 Minuten garen, nach 6 Minuten kraeftig durchschuetteln.",
                    "Heiss anrichten und servieren."
                ]
            ),
            MealTemplate(
                id: "rec_14_kasernen_power_dal",
                name: "14. 15-Minuten Kasernen-Power-Dal mit Blitz-Couscous",
                category: "Soups & Stews",
                ingredients: [
                    TemplateIngredient(pantryItemId: "cat-rote-linsen", name: "Rote Linsen getrocknet", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_1787655672345_105", name: "Kichererbsen (Greenland / PENNY)", grams: 240.0),
                    TemplateIngredient(pantryItemId: "food_1787655672345_106", name: "Bio Hartweizen Couscous (Natur Gut)", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_1787655672345_107", name: "Passierte Tomaten (San Fabio)", grams: 250.0),
                    TemplateIngredient(pantryItemId: "cat-kokosmilch-aldi", name: "Kokosmilch fettreduziert (Light)", grams: 180.0),
                    TemplateIngredient(pantryItemId: "cat-erdnussbutter-20166076", name: "Erdnussbutter Creamy / Crunchy", grams: 30.0)
                ],
                instructions: [
                    "120 g Couscous mit 150 ml kochendem Salzwasser uebergiessen, abdecken und 5 Minuten ziehen lassen.",
                    "150 g rote Linsen mit 350 ml kochendem Wasser in der Kasserolle 5 Minuten koecheln lassen.",
                    "Passierte Tomaten, Kokosmilch, Kichererbsen und Erdnussbutter einruehren. Mit Curry und Salz abschmecken.",
                    "3-4 Minuten saemig einkoecheln lassen und mit dem Couscous anrichten."
                ]
            ),
            MealTemplate(
                id: "recipe-kokos-tomaten-dal",
                name: "15. Cremiges Kokos-Tomaten-Dal mit 191g Basmati-Reis & Erdnussbutter",
                category: "Soups & Stews",
                ingredients: [
                    TemplateIngredient(pantryItemId: "cat-rote-linsen", name: "Rote Linsen getrocknet", grams: 180.0),
                    TemplateIngredient(pantryItemId: "cat-basmati-reis-191g", name: "Basmati Reis Spitzenqualitaet", grams: 191.0),
                    TemplateIngredient(pantryItemId: "cat-tomaten-penny", name: "Gehackte Tomaten in Tomatensaft", grams: 400.0),
                    TemplateIngredient(pantryItemId: "cat-kokosmilch-aldi", name: "Kokosmilch fettreduziert (Light)", grams: 200.0),
                    TemplateIngredient(pantryItemId: "cat-erdnussbutter-20166076", name: "Erdnussbutter Creamy / Crunchy", grams: 31.0)
                ],
                instructions: [
                    "Schritt 1 (Parallel-Start & Reis-Setup - 3 Min.): Wasserkocher starten. 191 g Basmati-Reis kurz kalt abspuelen, mit 380 ml kochendem Wasser und 0.5 TL Salz in den Reiskocher geben und starten (Cook-Modus).",
                    "Schritt 2 (Rote Linsen vorkoecheln - 5 Min.): 180 g rote Linsen in die Kasserolle einwiegen, mit 350-400 ml kochendem Wasser uebergiessen und auf mittlerer bis hoher Hitze 4-5 Minuten vorkoecheln, bis sie aufbrechen.",
                    "Schritt 3 (Tomaten, Kokos & Erdnussbutter emulgieren - 3 Min.): 400 g gehackte Tomaten (1 Dose), 200 ml Kokosmilch light und 31 g Erdnussbutter direkt einruehren, bis das Nussfett vollstaendig emulgiert ist.",
                    "Schritt 4 (Wuerzen & Saemig einkochen - 6-8 Min.): Mit 1 TL Kreuzkuemmel, 1.5 TL Curry/Kurkuma, 1 TL Salz und 0.5 TL Pfeffer abschmecken. Auf niedriger Stufe 6-8 Minuten saemig eindicken lassen.",
                    "Schritt 5 (Anrichten - 2 Min.): Den heissen Basmati-Reis auf einer tiefen Bowl anrichten und das samtige Dal daruebergeben.",
                    "Physiologische & Naehrstoff-Matrix: Perfekte biologische Wertigkeit (DIAAS = 1,0) durch Kombination von Linsen-Lysin und Reis-Methionin; ueber 32 g Ballaststoffe fuer Bristol-Typ-4 Stuhlmatrix."
                ]
            ),
            MealTemplate(
                id: "rec_16_soft_cookies",
                name: "16. Ultra-Soft One-Pot Chocolate Chip Cookies",
                category: "Snack",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_penny_butter", name: "Deutsche Markenbutter mildgesäuert", grams: 115.0),
                    TemplateIngredient(pantryItemId: "food_penny_brauner_zucker", name: "Brauner Rohrzucker", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_penny_zucker_weiss", name: "PENNY Zucker feine Körnung", grams: 50.0),
                    TemplateIngredient(pantryItemId: "food_1787584551166_76", name: "Frische Eier Bodenhaltung M", grams: 1.0),
                    TemplateIngredient(pantryItemId: "food_penny_vanillezucker", name: "Vanillin-Zucker (10er Pack)", grams: 8.0),
                    TemplateIngredient(pantryItemId: "food_penny_weizenmehl_405", name: "PENNY Weizenmehl Type 405", grams: 180.0),
                    TemplateIngredient(pantryItemId: "food_penny_backpulver", name: "Backpulver / Kaiser Natron", grams: 3.0),
                    TemplateIngredient(pantryItemId: "food_penny_feinsalz", name: "PENNY Jodsalz mit Fluorid", grams: 1.5),
                    TemplateIngredient(pantryItemId: "food_penny_zartbitter_schoko", name: "PENNY Zartbitter Schokolade 50%", grams: 150.0)
                ],
                instructions: [
                    "Nasse Zutaten direkt im Topf schmelzen: 115 g Butter direkt im grossen Kochtopf bei schwacher Hitze langsam schmelzen. Sofort vom Herd nehmen. 150 g braunen Zucker und 50 g weissen Zucker mit einem Loeffel oder Spatel einruehren, bis die Masse glaenzt. Anschliessend 1 Ei (Zimmertemperatur) und 1 Pck. Vanillezucker ca. 1 Minute mit dem Schneebesen cremig und glatt unterschlagen.",
                    "Trockene Zutaten direkt unterheben: 180 g Mehl, 3 g Natron/Backpulver und 1.5 g Feinsalz direkt in denselben Topf wiegen. Mit einem Loeffel oder Teigschaber nur so lange vorsichtig unterheben, bis kein trockenes Mehl mehr sichtbar ist (nicht uebermixen, damit die Cookies zart bleiben). 150 g grob gehackte Zartbitterschokolade gleichmaessig unter den weichen Teig heben.",
                    "Kuehlen im Topf (entscheidend fuer Soft & Chewy): Den gesamten Topf fuer 20-30 Minuten in den Kuehlschrank stellen. Das Abkuehlen des Fetts verhindert zuverlaessig, dass die Cookies im heissen Ofen zu flach und knusprig zerlaufen.",
                    "Backflaeche vorbereiten: Ein Backblech mit einem Bogen Backpapier auslegen. (Alternative: Falls direkt im ofenfesten Topf gebacken wird, pruefen, dass Griffe 100% ofenfest sind; Boden leicht fetten und entweder 2-3 Cookies mit Abstand oder den gesamten Teig als Giant Skillet Cookie Cake einfuellen).",
                    "Portionieren & Backen: Den Backofen auf 175 Grad C Ober-/Unterhitze vorheizen. Mit einem Loeffel oder Eisportionierer Teigbaellchen (ca. 2 gehaeufte Essloeffel / 50-60 g) formen und mit mindestens 5 cm Abstand auf das Blech setzen.",
                    "Backzeit & Weichheits-Regel: Exakt 9 bis 11 Minuten bei 175 Grad C backen. Wichtig: Die Cookies herausnehmen, sobald die Raender fest und zart goldbraun sind, die Mitte aber noch hell, gewoelbt und leicht unterbacken aussieht. Beim Abkuehlen auf dem Blech zieht die Restwaerme nach – so bleiben sie innen unvergleichlich weich und saftig (fudgy chew).",
                    "Variante Giant Cookie Cake: Den gekuehlten Teig gleichmaessig auf dem Boden des ofenfesten Topfes verstreichen. Bei 175 Grad C fuer 18-22 Minuten backen, bis der Rand fest ist und der Kern saftig bleibt. Direkt warm im Topf loeffeln."
                ]
            ),
            MealTemplate(
                id: "rec_17_snickers_bowl",
                name: "17. Anabole Snickers-Protein-Bowl",
                category: "Frühstück",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_speisequark_magerstufe", name: "Speisequark Magerstufe", grams: 250.0),
                    TemplateIngredient(pantryItemId: "food_haferflocken_zart", name: "Haferflocken zart", grams: 45.0),
                    TemplateIngredient(pantryItemId: "food_erdnussbutter", name: "Erdnussbutter", grams: 20.0),
                    TemplateIngredient(pantryItemId: "food_bluetenhonig", name: "Blütenhonig", grams: 15.0)
                ],
                instructions: [
                    "Creme aufschlagen: 250 g Speisequark mit 20 g Erdnussbutter, 1 TL Blütenhonig und 30–50 ml kaltem Wasser mit dem Löffel glattrühren, bis eine samtige Creme entsteht.",
                    "Haferflocken-Crunch: Die 45 g Haferflocken kurz in einer beschichteten Pfanne ohne Fett 90 Sekunden anrösten für intensives Röstaroma.",
                    "Schichten & Anrichten: Die gerösteten Flocken auf die Quarkcreme geben und mit dem restlichen Blütenhonig beträufeln."
                ],
                prepTimeMinutes: 5,
                cookTimeMinutes: 2,
                servings: 1,
                cuisineType: "Fitness",
                equipment: ["Schüssel", "Pfanne"]
            ),
            MealTemplate(
                id: "rec_18_thunfisch_rollini",
                name: "18. Rote Linsen Rollini mit Thunfisch & Schmelzkäse",
                category: "Mittagessen",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_rote_linsen_rollini", name: "Rote Linsen Rollini", grams: 120.0),
                    TemplateIngredient(pantryItemId: "food_thunfischfilet", name: "Thunfischfilet in eigenem Saft und Aufguss", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_scheibenkaese", name: "Scheibenkäse", grams: 30.0)
                ],
                instructions: [
                    "Linsen-Pasta kochen: 120 g Rote Linsen Rollini in kochendem Salzwasser 6–7 Minuten al dente kochen. Ca. 50 ml Kochwasser abschöpfen, dann Nudeln abgießen.",
                    "Sauce & Emulsion: Den Thunfisch samt Aufguss und dem abgeschöpften Kochwasser zurück in den warmen Topf geben und mit den Nudeln vermengen.",
                    "Käse-Finish: Den Scheibenkäse in feine Streifen schneiden, unter die heißen Nudeln heben und bei geschlossenem Deckel 60 Sekunden schmelzen lassen."
                ],
                prepTimeMinutes: 5,
                cookTimeMinutes: 8,
                servings: 1,
                cuisineType: "Mediterran",
                equipment: ["Kochtopf"]
            ),
            MealTemplate(
                id: "rec_19_zweibohnen_pfanne",
                name: "19. Pikante Zweibohnen-Pfanne mit Ziegenkäse",
                category: "Abendessen",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_schwarze_bohnen", name: "Schwarze Bohnen", grams: 150.0),
                    TemplateIngredient(pantryItemId: "food_rote_kidney_bohnen", name: "Rote Kidney Bohnen 200g", grams: 200.0),
                    TemplateIngredient(pantryItemId: "food_ziegenkaese", name: "Ziegenkäse", grams: 40.0)
                ],
                instructions: [
                    "Bohnen spülen: Schwarze Bohnen und Kidneybohnen im Sieb kurz kalt abbrausen.",
                    "Stärke-Bindung in der Pfanne: Bohnen mit ca. 50 ml Wasser in die heiße Pfanne geben. Ca. 20 % der Bohnen mit der Gabel zerdrücken, damit natürliche Stärke austritt und eine sämige Sauce bindet.",
                    "Ziegenkäse-Finish: Den Ziegenkäse zerbröckeln, auf die heißen Bohnen geben und bei milder Hitze cremig anschmelzen lassen."
                ],
                prepTimeMinutes: 5,
                cookTimeMinutes: 6,
                servings: 1,
                cuisineType: "Tex-Mex",
                equipment: ["Pfanne"]
            ),
            MealTemplate(
                id: "rec_20_sauerkraut_matjes",
                name: "20. Milder Sauerkraut-Matjes-Salat mit Honig",
                category: "Abendessen",
                ingredients: [
                    TemplateIngredient(pantryItemId: "food_delikatess_sauerkraut", name: "Delikatess Sauerkraut von Spreewald Prinzessin", grams: 200.0),
                    TemplateIngredient(pantryItemId: "food_edle_matjesfilets", name: "Edle Matjesfilets", grams: 128.0),
                    TemplateIngredient(pantryItemId: "food_bluetenhonig", name: "Blütenhonig", grams: 10.0)
                ],
                instructions: [
                    "Sauerkraut abtropfen: 200 g Sauerkraut im Sieb abtropfen lassen und mit einer Gabel auflockern.",
                    "Säure mildern: Den Blütenhonig mit 1 EL Wasser verrühren und unter das Sauerkraut heben, um die Säurespitze harmonisch abzufedern.",
                    "Matjes anrichten: Die Edlen Matjesfilets in Streifen schneiden und kalt auf das milde Krautbett legen (nicht erhitzen)."
                ],
                prepTimeMinutes: 5,
                cookTimeMinutes: 0,
                servings: 1,
                cuisineType: "Nordisch",
                equipment: ["Teller"]
            )
        ]

    public static var initialTemplates: [MealTemplate] {
        return []
    }

    public static func getMasterTemplates() -> [MealTemplate] {
        return []
    }

    public static func getMasterShoppingList() -> [ShoppingItem] {
        return []
    }

    public static func getMasterReceipts() -> [ReceiptRecord] {
        return [
            ReceiptRecord(
                id: "receipt_penny_cookies_20260912",
                date: Date(timeIntervalSince1970: 1789231500),
                storeName: "PENNY",
                totalAmount: 11.79,
                imageFilename: nil,
                items: [
                    ReceiptLineItem(id: "line_p1", rawText: "MARKENBUTTER 250G", parsedPrice: 1.59, matchedPantryItemId: "food_penny_butter", matchedPantryItemName: "Deutsche Markenbutter mildgesäuert", previousPrice: 1.59, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p2", rawText: "ROHROHRZUCKER 500G", parsedPrice: 1.49, matchedPantryItemId: "food_penny_brauner_zucker", matchedPantryItemName: "Brauner Rohrzucker", previousPrice: 1.49, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p3", rawText: "FEINZUCKER 1000G", parsedPrice: 1.19, matchedPantryItemId: "food_penny_zucker_weiss", matchedPantryItemName: "PENNY Zucker feine Körnung", previousPrice: 1.19, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p4", rawText: "FRISCHE EIER 10ER", parsedPrice: 1.99, matchedPantryItemId: "food_1787584551166_76", matchedPantryItemName: "Frische Eier Bodenhaltung M", previousPrice: 1.99, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p5", rawText: "VANILLIN-ZUCKER 10X", parsedPrice: 0.59, matchedPantryItemId: "food_penny_vanillezucker", matchedPantryItemName: "Vanillin-Zucker (10er Pack)", previousPrice: 0.59, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p6", rawText: "WEIZENMEHL 405 1KG", parsedPrice: 0.79, matchedPantryItemId: "food_penny_weizenmehl_405", matchedPantryItemName: "PENNY Weizenmehl Type 405", previousPrice: 0.79, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p7", rawText: "BACKPULVER / NATRON", parsedPrice: 0.49, matchedPantryItemId: "food_penny_backpulver", matchedPantryItemName: "Backpulver / Kaiser Natron", previousPrice: 0.49, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p8", rawText: "JODSALZ MIT FLUORID", parsedPrice: 0.29, matchedPantryItemId: "food_penny_feinsalz", matchedPantryItemName: "PENNY Jodsalz mit Fluorid", previousPrice: 0.29, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p9", rawText: "ZARTBITTER 50% 2X", parsedPrice: 1.98, matchedPantryItemId: "food_penny_zartbitter_schoko", matchedPantryItemName: "PENNY Zartbitter Schokolade 50%", previousPrice: 1.98, confidenceScore: 0.98, isConfirmed: true),
                    ReceiptLineItem(id: "line_p10", rawText: "BACKPAPIER ZUSCHNIT", parsedPrice: 1.19, matchedPantryItemId: "food_penny_backpapier", matchedPantryItemName: "PENNY Backpapier Zuschnitte", previousPrice: 1.19, confidenceScore: 0.98, isConfirmed: true)
                ],
                notes: "PENNY Einkauf fuer Soft Cookies Rezeptur"
            )
        ]
    }
}
