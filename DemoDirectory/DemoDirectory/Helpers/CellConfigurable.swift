//
//  CellConfigurator.swift
//  development-pods-instantsearch
//
//  Created by Vladislav Fitc on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import SDWebImage
import InstantSearch

struct MovieTableViewCellConfigurator: InstantSearch.CellConfigurable {
  
  static var cellIdentifier: String = "movieCell"
  
  typealias Model = Movie
  
  let movie: Movie
  
  init(model: Movie, indexPath: IndexPath) {
    self.movie = model
  }

}

struct MovieCellViewState {
  
  func configure(_ cell: UIView & MovieCell) -> (Movie) -> () {
    return { movie in
      cell.artworkImageView.sd_setImage(with: movie.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }
      cell.titleLabel.text = movie.title
      cell.genreLabel.text = movie.genre.joined(separator: ", ")
      cell.yearLabel.text = String(movie.year)
    }
  }
  
  func configure(_ cell: UIView & MovieCell) -> (Product) -> () {
    return { product in
      cell.artworkImageView.sd_setImage(with: product.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }
      cell.titleLabel.text = product.name
      cell.genreLabel.text = product.brand
      cell.yearLabel.text = product.type
    }
  }
  
}

struct MovieHitCellViewState {
  
  func configure(_ cell: UIView & MovieCell) -> (Hit<Movie>) -> () {
    return { movieHit in
      let movie = movieHit.object
      cell.artworkImageView.sd_setImage(with: movie.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }

      switch movieHit.highlightResult {
      case .dictionary(let dict):
        if let title = dict["title"] {
          switch title {
          case .value(let theTitle):
            cell.titleLabel.attributedText = NSAttributedString(highlightedResults: [theTitle], separator: NSAttributedString(string: ", "), attributes: [.font: UIFont.systemFont(ofSize: cell.titleLabel.font.pointSize, weight: .black)])
          default: break
          }

        }
      default: break
      }

      cell.genreLabel.text = movie.genre.joined(separator: ", ")
      cell.yearLabel.text = String(movie.year)
    }
  }

  
}

extension MovieHitCellViewState {
  
  func configure(_ cell: UIView & MovieCell) -> (Hit<ShopItem>) -> () {
    return { itemHit in
      let item = itemHit.object
      cell.artworkImageView.sd_setImage(with: item.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }

      switch itemHit.highlightResult {
      case .dictionary(let dict):
        if let title = dict["name"] {
          switch title {
          case .value(let theTitle):
            cell.titleLabel.attributedText = NSAttributedString(highlightedResults: [theTitle], separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: UIColor.red])
          default: break
          }

        }
      default: break
      }

      cell.genreLabel.text = item.brand
      cell.yearLabel.text = item.description
    }
  }
  
}

extension ActorHitCollectionViewCellViewState {
  
  func configure(_ cell: ActorCollectionViewCell) -> (Hit<QuerySuggestion>) -> () {
    return { brandHit in
      if let highlightedName = brandHit.hightlightedString(forKey: "query") {
        cell.nameLabel.attributedText = NSAttributedString(highlightedString: highlightedName, attributes: [.font:
          UIFont.systemFont(ofSize: cell.nameLabel.font.pointSize, weight: .black)])
      }
    }
  }
  
}


struct ActorCollectionViewCellViewState {
  
  func configure(_ cell: ActorCollectionViewCell) -> (Actor) -> () {
    return { actor in
      cell.nameLabel.text = actor.name
    }
  }
  
}

struct ActorHitCollectionViewCellViewState {
  
  func configure(_ cell: ActorCollectionViewCell) -> (Hit<Actor>) -> () {
    return { actorHit in
      if let highlightedName = actorHit.hightlightedString(forKey: "name") {
        cell.nameLabel.attributedText = NSAttributedString(highlightedString: highlightedName, attributes: [.font:
          UIFont.systemFont(ofSize: cell.nameLabel.font.pointSize, weight: .black)])
      }
    }
  }
  
}



protocol CellConfigurable {
  associatedtype T
  static func configure(_ cell: UITableViewCell) -> (T) -> Void
}

struct EmptyCellConfigurator: CellConfigurable {
  static func configure(_ cell: UITableViewCell) -> (Any) -> Void {
    return { _ in }
  }
}

struct MovieCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Movie) -> Void {
    return { movie in
      cell.textLabel?.text = movie.title
      cell.detailTextLabel?.text = movie.genre.joined(separator: ", ")
      cell.imageView?.sd_setImage(with: movie.image, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }
  
}

struct ActorCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Actor) -> Void {
    return { actor in
      cell.textLabel?.text = actor.name
      cell.detailTextLabel?.text = "rating: \(actor.rating)"
      let baseImageURL = URL(string: "https://image.tmdb.org/t/p/w45")
      let imageURL = baseImageURL?.appendingPathComponent(actor.image_path)
      cell.imageView?.sd_setImage(with: imageURL, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }

}

struct MovieHitCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Hit<Movie>) -> Void {
    return { movieHit in
      let movie = movieHit.object
      if let highlightedTitle = movieHit.hightlightedString(forKey: "title") {
        if let textLabel = cell.textLabel {
          textLabel.attributedText = NSAttributedString(highlightedString: highlightedTitle, attributes: [.font:
            UIFont.systemFont(ofSize: textLabel.font.pointSize, weight: .black)])

        }
      }
      
      cell.detailTextLabel?.text = movie.genre.joined(separator: ", ")
      cell.imageView?.sd_setImage(with: movie.image, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }
  
}
