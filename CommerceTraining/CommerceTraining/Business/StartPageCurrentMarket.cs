using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CommerceTraining.Models.Pages;
using EPiServer;
using EPiServer.Core;
using Mediachase.Commerce;
using Mediachase.Commerce.Markets;

namespace CommerceTraining.Business
{
    public class StartPageCurrentMarket : ICurrentMarket
    {
        private readonly IContentLoader _contentLoader;
        private readonly IMarketService _marketService;

        public StartPageCurrentMarket(IContentLoader contentLoader, IMarketService marketService)
        {
            _contentLoader = contentLoader;
            _marketService = marketService;
        }

        public IMarket GetCurrentMarket()
        {
            MarketId marketId = MarketId.Default;
            try
            {
                var startpage = _contentLoader.Get<StartPage>(ContentReference.StartPage);
                if (startpage.MarketId == null)
                {
                    var marketString = startpage.MarketId;
                    marketId = new MarketId(marketString);
                }
            }
            catch
            {
                marketId = MarketId.Default;
            }
            return _marketService.GetMarket(marketId);
        }

        public void SetCurrentMarket(MarketId marketId)
        {
        }
    }
}