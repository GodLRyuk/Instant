import 'package:flutter/material.dart';
import 'package:instant/pages/home.dart';
import 'package:instant/pages/support/supportWidget.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';

class Singleproductdetails extends StatefulWidget {
  const Singleproductdetails({super.key});

  @override
  State<Singleproductdetails> createState() => _SingleproductdetailsState();
}

class _SingleproductdetailsState extends State<Singleproductdetails> {
  int a = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
        ),
      ),
      // appBar: PreferredSize(
      //   preferredSize: const Size.fromHeight(90),
      //   child: Container(
      //     decoration: const BoxDecoration(
      //       gradient: LinearGradient(
      //         colors: [
      //           Color(0xfff7d486),
      //           Color(0Xffe9b7ce),
      //         ],
      //       ),
      //     ),
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         AppBar(
      //           backgroundColor: Colors.transparent,
      //           elevation: 0,
      //           title: SizedBox(
      //             height: 40,
      //             child: GestureDetector(
      //               onTap: () {
      //                 Navigator.pushReplacement(
      //                   context,
      //                   MaterialPageRoute(
      //                     builder: (context) => const Homepage(),
      //                   ),
      //                 );
      //               },
      //               child: const Icon(
      //                 Icons.arrow_back_ios_new_outlined,
      //                 color: Colors.black,
      //               ),
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 0, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  "images/product.jpg",
                  width: MediaQuery.of(context).size.width,
                ),
              ),
              Text(
                "Amul Taaza Toned Fresh Milk (Pouch)",
                style: Supportwidget.StextHeadingStyle(),
              ),
              Text(
                "See All Amul Products >",
                style: Supportwidget.otherProductsHeadding(),
              ),
              const SizedBox(height: 8.0),
              Text(
                "500 ml",
                style: Supportwidget.SproductQtyStyle(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\u20B9 25",
                    style: Supportwidget.SproductPriceStyle(),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (a > 1) {
                            --a;
                          }
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      Text(
                        a.toString(),
                        style: Supportwidget.SproductPriceStyle(),
                      ),
                      const SizedBox(width: 15.0),
                      GestureDetector(
                        onTap: () {
                          ++a;
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              // ExpansionTile Section
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildExpansionTileBox(
                      "Product Description",
                      "This product is fresh and packed under hygienic conditions.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build an ExpansionTileCard inside a container with shadow
  Widget _buildExpansionTileBox(String title, String subTitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.only(left: 10), // Space between boxes
      decoration: BoxDecoration(
        color: Colors.white, // Box background color
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.8), // Shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: ExpansionTileCard(
        title: Text(title), // Optional subtitle
        baseColor: Colors.white, // Base background color
        expandedColor: Colors.white, // Expanded background color
        elevation: 0, // No elevation to remove the top border line
        children: [
          ListTile(
            title: Text(subTitle),
            contentPadding: EdgeInsets.zero, // Remove padding from ListTile
          ),
        ],
      ),
    );
  }
}
