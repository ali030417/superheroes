import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:superheroes/pages/main_page.dart';

class MainBloc {
  static const minSymbols = 3;
  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();
  final favoriteSuperheroesSubject =
      BehaviorSubject<List<SuperheroInfo>>.seeded(SuperheroInfo.moked);
  final searchedSuperheroesSubject = BehaviorSubject<List<SuperheroInfo>>();
  final currentTextSubject = BehaviorSubject<String>.seeded('');

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;

  Stream<List<SuperheroInfo>> observeSearchedSuperheroes() =>
      searchedSuperheroesSubject;
  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() =>
      favoriteSuperheroesSubject;

  MainBloc() {
    stateSubject.add(MainPageState.noFavorites);

    textSubscription = Rx.combineLatest2<String, List<SuperheroInfo>, MainPageStateInfo>(
        currentTextSubject
            .distinct()
            .debounceTime(const Duration(milliseconds: 500)),
        favoriteSuperheroesSubject,
        (searchedText, favorites) => MainPageStateInfo(searchedText, favorites.isNotEmpty)).listen((value) {
      print('Cange $value');
      searchSubscription?.cancel();
      if (value.searchText.isEmpty) {
        if(value.haveFavorites){
          stateSubject.add(MainPageState.favorites);
        }else{
          stateSubject.add(MainPageState.noFavorites);
        }
        stateSubject.add(MainPageState.favorites);
      } else if (value.searchText.length < minSymbols) {
        stateSubject.add(MainPageState.minSymbols);
      } else {
        SearchForSuperheroes(value.searchText);
      }
    });
  }

  void SearchForSuperheroes(final String text) {
    stateSubject.add(MainPageState.loading);
    searchSubscription = search(text).asStream().listen((searchResults) {
      if (searchResults.isEmpty) {
        stateSubject.add(MainPageState.nothingFound);
      } else {
        searchedSuperheroesSubject.add(searchResults);
        stateSubject.add(MainPageState.searchResults);
      }
    }, onError: (error, StackTrace) {
      stateSubject.add(MainPageState.loading);
    });
  }

  Future<List<SuperheroInfo>> search(final String text) async {
    await Future.delayed(const Duration(seconds: 1));
    return SuperheroInfo.moked.where((superheroInfo) => superheroInfo.name.toLowerCase().contains(text.toLowerCase())).toList();
  }

  Stream<MainPageState> observeMainPageState() => stateSubject;

  void remoteFavorite (){
    final List<SuperheroInfo> currentFavorites = favoriteSuperheroesSubject.value;
    if(currentFavorites.isEmpty){
      favoriteSuperheroesSubject.add(SuperheroInfo.moked);
    } else {
      favoriteSuperheroesSubject.add(currentFavorites.sublist(0, currentFavorites.length-1));
    }
  }

  void nextState() {
    final currentState = stateSubject.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubject.add(nextState);
  }

  void updateText(final String? text) {
    currentTextSubject.add(text ?? '');
  }

  void dispose() {
    stateSubject.close();
    favoriteSuperheroesSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();

    textSubscription?.cancel();
  }
}

enum MainPageState {
  noFavorites,
  minSymbols,
  loading,
  nothingFound,
  loadingError,
  searchResults,
  favorites,
}

class SuperheroInfo {
  final String name;
  final String realName;
  final String imageUrl;

  const SuperheroInfo({
    required this.name,
    required this.realName,
    required this.imageUrl,
  });

  @override
  String toString() {
    return 'SuperheroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;

  static const moked = [
    SuperheroInfo(
      name: 'Batman',
      realName: 'Bruce Wayne',
      imageUrl:
          'https://www.superherodb.com/pictures2/portraits/10/100/639.jpg',
    ),
    SuperheroInfo(
      name: 'Ironman',
      realName: 'Tony Stark',
      imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/85.jpg',
    ),
    SuperheroInfo(
      name: 'Venom',
      realName: 'Eddie Brock',
      imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/22.jpg',
    ),
  ];
}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

   MainPageStateInfo(this.searchText, this.haveFavorites);

  @override
  String toString() {
    return 'MainPageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;
}
