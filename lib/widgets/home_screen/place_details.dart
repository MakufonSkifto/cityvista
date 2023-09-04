import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cityvista/other/models/city_place.dart';
import 'package:cityvista/other/utils.dart';
import 'package:cityvista/other/constants.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaceDetails extends StatelessWidget {
  final CityPlace place;

  const PlaceDetails({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    List<Widget> images = place.images.map((item) {
      return GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            pageBuilder: (BuildContext context, _, __) {
              return Container(
                color: Colors.black.withOpacity(.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel_outlined, color: Colors.white)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1,
                        maxScale: 3,
                        child: CachedNetworkImage(
                          imageUrl: item,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }
          );
        },
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fill,
            child: CachedNetworkImage(
              imageUrl: item,
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Place"),
        centerTitle: false,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                if (place.website != null)
                  PopupMenuItem(
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        launchUrl(Uri.parse(place.website!));
                      },
                      icon: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.globe),
                          SizedBox(width: 10),
                          Text("Website")
                        ],
                      )
                    ),
                  ),
                if (place.phone != null)
                  PopupMenuItem(
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        launchUrl(Uri.parse("tel:${place.phone}"));
                      },
                      icon: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.phone),
                          SizedBox(width: 10),
                          Text("Phone")
                        ],
                      )
                    ),
                  ),
                PopupMenuItem(
                  child: IconButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final availableMaps = await MapLauncher.installedMaps;

                      if (availableMaps.isEmpty) {
                        await Clipboard.setData(
                          ClipboardData(text: place.address)
                        );
                        Utils.alertPopup(
                          false,
                          "You don't have any Maps app that we support installed!"
                          "We have copied the full address to your clipboard."
                        );
                        return;
                      } else {
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    children: <Widget>[
                                      for (var map in availableMaps)
                                        ListTile(
                                          onTap: () => map.showMarker(
                                            coords: Coords(
                                              place.geoPoint.latitude,
                                              place.geoPoint.longitude
                                            ),
                                            title: place.name,
                                          ),
                                          title: Text(map.mapName),
                                          leading: SvgPicture.asset(
                                            map.icon,
                                            height: 30.0,
                                            width: 30.0,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                    icon: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.map),
                        SizedBox(width: 10),
                        Text("Open in Maps")
                      ],
                    )
                  ),
                ),
                PopupMenuItem(
                  child: IconButton(
                    onPressed: () {},
                    icon: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.flag),
                        SizedBox(width: 10),
                        Text("Report")
                      ],
                    )
                  ),
                ),
              ];
            },
          ),
        ],
        elevation: 5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: kTextColor.withOpacity(.1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CarouselSlider(
                items: images,
                options: CarouselOptions(
                  enableInfiniteScroll: false,
                  enlargeFactor: 0.2,
                  enlargeCenterPage: true,
                  viewportFraction: .7,
                  aspectRatio: 16 / 8,
                  scrollDirection: Axis.horizontal,
                  autoPlay: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Column(
                children: [
                  Text(place.name, style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23
                  )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Utils.buildPlaceStars(place),
                      const SizedBox(width: 5),
                      Utils.buildPriceRange(place)
                    ],
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(place.description, style: const TextStyle(
                      fontSize: 15
                    )),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: buildReviews(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReviews() {
    if (place.reviews.isEmpty) {
      return SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "No reviews yet!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (FirebaseAuth.instance.currentUser!.uid != place.authorUid)
              ElevatedButton(
                onPressed: () {},
                child: const Text("Leave a Review")
              )
          ],
        )
      );
    }

    return const Text("hey");
  }
}