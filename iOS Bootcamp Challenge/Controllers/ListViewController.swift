//
//  ListViewController.swift
//  iOS Bootcamp Challenge
//
//  Created by Jorge Benavides on 26/09/21.
//

import UIKit
import SVProgressHUD

class ListViewController: UICollectionViewController, UISearchResultsUpdating{

    private var pokemons: [Pokemon] = []
    private var resultPokemons: [Pokemon] = []
    private var clickedPkmn: Pokemon?

    // TODO: Use UserDefaults to pre-load the latest search at start

    private var latestSearch: String?

    lazy private var searchController: SearchBar = {
        let searchController = SearchBar("Search a pokemon", delegate: nil)
        searchController.text = latestSearch
        searchController.showsCancelButton = !searchController.isSearchBarEmpty
        return searchController
    }()

    private var isFirstLauch: Bool = true

    // TODO: Add a loading indicator when the app first launches and has no pokemons - DONE!

    private var shouldShowLoader: Bool = true
    private let myActivityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        myActivityIndicator.center = view.center
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        myActivityIndicator.hidesWhenStopped = false
        myActivityIndicator.startAnimating()
        
        setup()
        setupUI()
        
        view.addSubview(myActivityIndicator)
    }

    // MARK: Setup

    private func setup() {
        title = "Pokédex"

        // Customize navigation bar.
        guard let navbar = self.navigationController?.navigationBar else { return }

        navbar.tintColor = .black
        navbar.titleTextAttributes = [.foregroundColor: UIColor.black]
        navbar.prefersLargeTitles = true

        // Set up the searchController parameters.
        navigationItem.searchController = searchController
        definesPresentationContext = true

        refresh()
    }

    private func setupUI() {

        // Set up the collection view.
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.indicatorStyle = .white

        // Set up the refresh control as part of the collection view when it's pulled to refresh.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.sendSubviewToBack(refreshControl)
    }

    // MARK: - UISearchViewController

    private func filterContentForSearchText(_ searchText: String) {
        // filter with a simple contains searched text
        resultPokemons = pokemons
            .filter {
                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
            }
            .sorted {
                $0.id < $1.id
            }

        collectionView.reloadData()
    }

    // TODO: Implement the SearchBar - DONE!
    
    func updateSearchResults(for searchController: UISearchController){
        guard let text = searchController.searchBar.text else{ return }
        filterContentForSearchText(text)
    }
    

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultPokemons.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokeCell.identifier, for: indexPath) as? PokeCell
        else { preconditionFailure("Failed to load collection view cell") }
        cell.pokemon = resultPokemons[indexPath.item]
        myActivityIndicator.stopAnimating()
        myActivityIndicator.hidesWhenStopped = true
        return cell
    }

    // MARK: - Navigation

    // TODO: Handle navigation to detail view controller - DONE!
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        self.clickedPkmn = resultPokemons[indexPath.item]
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDetailViewControllerSegue"{
            let destinationVC = segue.destination as! DetailViewController
            destinationVC.pokemon = clickedPkmn
        }
    }

    // MARK: - UI Hooks

    @objc func refresh() {
        shouldShowLoader = true

        var pokemons: [Pokemon] = []

        // TODO: Wait for all requests to finish before updating the collection view - DONE!

        PokeAPI.shared.get(url: "pokemon?limit=30", onCompletion: { (list: PokemonList?, _) in
            guard let list = list else { return }
            list.results.forEach { result in
                PokeAPI.shared.get(url: "/pokemon/\(result.id)/", onCompletion: { (pokemon: Pokemon?, _) in
                    guard let pokemon = pokemon else { return }
                    pokemons.append(pokemon)
                    self.pokemons = pokemons
                    if self.pokemons.count == list.results.count {
                    self.didRefresh()
                    }
                })
            }
        })
    }

    private func didRefresh() {
        shouldShowLoader = false

        guard
            let collectionView = collectionView,
            let refreshControl = collectionView.refreshControl
        else { return }

        refreshControl.endRefreshing()

        filterContentForSearchText("")
    }

}
