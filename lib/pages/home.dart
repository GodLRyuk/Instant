// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:instant/pages/singleproductdetails.dart';
import 'package:instant/pages/support/supportWidget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xfff7d486),
                Color(0Xffe9b7ce),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.asset(
                    "images/useraccount.png",
                    width: 40,
                    height: 40,
                  ),
                ),
                title: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search..",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.search,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                ),
                Text(
                  "Top Trending Today",
                  style: Supportwidget.textHeadingStyle(),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(3, (index) => trending_product()),
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "All Category",
                  style: Supportwidget.textHeadingStyle(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return group_product();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget trending_product() {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
      child: Material(
        elevation: 7.0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset("images/product.jpg"),
              Text(
                "Amul Taaza",
                style: Supportwidget.productDetailsStyle(),
              ),
              Text(
                "Toned Fresh Milk...",
                style: Supportwidget.productDetailsStyle(),
              ),
              Text(
                "500 ml",
                style: Supportwidget.productQtyStyle(),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\u20B9 25",
                    style: Supportwidget.productPriceStyle(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Singleproductdetails(),
                        ),
                      );
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget group_product() {
    return GestureDetector(
      onTap: () {
        // Define the action when the product is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Singleproductdetails(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.only(top: 20, left: 15),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligns children to the left
              children: [
                Image.asset(
                  "images/product.jpg",
                  width: 80,
                ),
                const SizedBox(
                    height: 8), // Add some spacing between image and text
                Text(
                  "Amul Taaza",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left, // Optional: Ensures left alignment
                ),
                const Text(
                  "\u20B9 25",
                  textAlign: TextAlign.left, // Optional: Ensures left alignment
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
