//
//  NewsListViewController.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import UIKit
import Combine

final class NewsListViewController: UIViewController {
    private let viewModel: NewsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        return table
    }()
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = "Search news..."
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()
    
    private let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "newspaper")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyStateTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "No Data"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emptyStateDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Unable to load news articles. Please check your connection and try again."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    init(viewModel: NewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadTopHeadlines(refresh: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "News"
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationController?.navigationBar.prefersLargeTitles = true
        
        searchController.searchBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        tableView.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateTitleLabel)
        emptyStateView.addSubview(emptyStateDescriptionLabel)
        
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateTitleLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 24),
            emptyStateTitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateTitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescriptionLabel.topAnchor.constraint(equalTo: emptyStateTitleLabel.bottomAnchor, constant: 12),
            emptyStateDescriptionLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescriptionLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescriptionLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$newsArticles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                self?.tableView.reloadData()
                self?.updateEmptyState(articles: articles)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading && self.viewModel.newsArticles.isEmpty {
                    self.loadingIndicator.alpha = 0
                    self.loadingIndicator.startAnimating()
                    self.emptyStateView.isHidden = true
                    
                    UIView.animate(withDuration: 0.3) {
                        self.loadingIndicator.alpha = 1.0
                    }
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.loadingIndicator.alpha = 0
                    }) { _ in
                        self.loadingIndicator.stopAnimating()
                    }
                    self.updateEmptyState(articles: self.viewModel.newsArticles)
                }
                self.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$searchQuery
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateEmptyState(articles: self?.viewModel.newsArticles ?? [])
            }
            .store(in: &cancellables)
    }
    
    private func updateEmptyState(articles: [Article]) {
        let isEmpty = articles.isEmpty && !viewModel.isLoading
        let wasHidden = emptyStateView.isHidden
        
        if isEmpty && wasHidden {
            emptyStateView.alpha = 0
            emptyStateView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            emptyStateView.isHidden = false
            tableView.isHidden = true
            
            if !viewModel.searchQuery.isEmpty {
                emptyStateTitleLabel.text = "No Results"
                emptyStateDescriptionLabel.text = "No articles found for your search. Try different keywords."
            } else {
                emptyStateTitleLabel.text = "No Data"
                emptyStateDescriptionLabel.text = "Unable to load news articles. Please check your connection and try again."
            }
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
                self.emptyStateView.alpha = 1.0
                self.emptyStateView.transform = .identity
            })
        } else if !isEmpty && !wasHidden {
            UIView.animate(withDuration: 0.2, animations: {
                self.emptyStateView.alpha = 0
                self.emptyStateView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                self.emptyStateView.isHidden = true
                self.tableView.isHidden = false
            }
        }
    }
    
    @objc private func refreshData() {
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.alpha = 0.7
        }) { _ in
            if self.searchController.searchBar.text?.isEmpty ?? true {
                self.viewModel.loadTopHeadlines(refresh: true)
            } else {
                self.viewModel.searchNews(query: self.searchController.searchBar.text ?? "", refresh: true)
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.5) {
                self.tableView.alpha = 1.0
            }
        }
    }
}

extension NewsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.newsArticles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.newsArticles.count else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsTableViewCell.identifier, for: indexPath) as! NewsTableViewCell
        cell.configure(with: viewModel.newsArticles[indexPath.row])
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.4, delay: Double(indexPath.row) * 0.05, options: [.curveEaseOut], animations: {
            cell.alpha = 1.0
            cell.transform = .identity
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.newsArticles.count else { return }
        let article = viewModel.newsArticles[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let detailVC = NewsDetailViewController(article: article, viewModel: self.viewModel)
            detailVC.view.alpha = 0
            self.navigationController?.pushViewController(detailVC, animated: false)
            
            UIView.animate(withDuration: 0.3) {
                detailVC.view.alpha = 1.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let threshold = 5
        if indexPath.row >= viewModel.newsArticles.count - threshold && !viewModel.isLoadingMore {
            viewModel.loadMoreArticles()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewModel.isLoadingMore {
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 50))
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            footerView.addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
            ])
            return footerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.isLoadingMore ? 50 : 0
    }
}

extension NewsListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        viewModel.searchNews(query: query, refresh: true)
        searchController.dismiss(animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchQuery = ""
        viewModel.loadTopHeadlines(refresh: true)
    }
}
